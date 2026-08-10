# platform-helm — meta Helm chart for Argo CD-driven platform bootstrap

## What this repo is

`platform-helm` ships a single meta Helm chart, `platform-core`, that bootstraps a
Kubernetes cluster's platform layer (Gatekeeper, cert-manager, Crossplane, Istio,
Gateway API, monitoring stack, KEDA, NATS, Argo Events, etc.) as Argo CD
`Application` CRDs rather than direct workloads. Each component is opt-in via a
toggle in `values.yaml`; Argo CD owns the full lifecycle (install, upgrade,
rollback, drift detection) downstream.

Remote: `https://github.com/DramisInfo/platform-helm.git` (default branch `main`).
License: MIT.

## Layout

```
platform-helm/
├── README.md                      # user-facing docs, components table, install/upgrade/validate
├── CONTRIBUTING.md                # PR process, branch naming, SemVer on Chart.yaml
├── CODE_OF_CONDUCT.md             # Contributor Covenant v2.1
├── SECURITY.md                    # private disclosure via GitHub Security Advisories
├── LICENSE                        # MIT
├── .gitattributes                 # marks .github/workflows/*.lock.yml as linguist-generated
├── .gitignore                     # ignores *.tgz, node_modules, .helm-dry-run, portforward.log
├── .github/
│   ├── agents/                    # custom GitHub Copilot agents (see Conventions)
│   ├── aw/actions-lock.json       # pinned GitHub Actions SHAs for gh-aw workflows
│   ├── prompts/                   # Copilot prompt files (add/update/troubleshoot)
│   ├── workflows/                 # helm-lint, release, test-chart-combinations, weekly-version-bump
│   ├── ISSUE_TEMPLATE/            # bug_report.md, feature_request.md
│   ├── PULL_REQUEST_TEMPLATE.md   # requires helm lint + helm template + version bump
│   └── dependabot.yml             # weekly GitHub Actions bumps (limit 5 open PRs)
└── platform-core/                 # the actual Helm chart
    ├── Chart.yaml                 # version 0.69.0, appVersion 1.6.0 (chart-releaser publishes)
    ├── values.yaml                # bootstrap.* toggles, global.clusterName/azure, jetstream, gateway, etc.
    ├── README.md                  # Grafana-specific value docs (plugins/datasources/provisioning)
    ├── GATEKEEPER-POLICIES.md     # library-based policies, exclusions, enforcement modes
    ├── .helmignore
    └── templates/
        ├── _helpers.tpl           # defaultRetry / extendedRetry include helpers
        ├── argocd-projects.yaml   # 6 AppProjects: foundations, networking, observability, infra, product-workspaces, data
        ├── platform-config.yaml   # ConfigMap + Namespace (sync-wave -201/-200)
        ├── hermes-sre-rbac.yaml   # read-only SA/ClusterRole for agent cluster investigation
        └── argo-applications/
            ├── argo-events/  atlas/  beyla/  cert-manager/  cnpg/  crossplane/
            ├── envoy-gateway/  external-secret-operator/  gatekeeper/  gateway-api/
            ├── grafana/  istio/  k6-operator/  keda/  kubevela/  loki/  nats/
            ├── prometheus/  tempo/  terraform-operator/
            └── <component>/<component>.yaml  (one Application manifest per component)
```

## Conventions

**Language/tooling**
- Helm v3 only. CI pins `azure/setup-helm@v5` to `v3.14.4`.
- Chart packaging + releases via `helm/chart-releaser-action@v1.7.0`
  (`.github/workflows/release.yaml`, runs on push to `main`).
- Helm lint and template render run locally with `helm` from `platform-core/`.

**Validation commands (run before opening a PR)**
```bash
helm lint platform-core
helm template platform-core ./platform-core                # full render
helm template platform-core ./platform-core -f my-values.yaml
```

**CI checks that must pass (see `.github/workflows/`)**
- `Helm Lint` — `helm lint platform-core`.
- `Test Chart Combinations` — required check. Renders 6 matrix combinations
  (`all-disabled`, `gatekeeper-only`, `monitoring-only`, `keda-and-nats`,
  `optional-components`, `all-enabled`) and aggregates results.

**Branch + commit conventions**
- Default branch: `main`. Branch off `main`: `feat/your-feature-name`
  (per `CONTRIBUTING.md`).
- Conventional Commits for PR titles: `feat:`, `fix:`, `docs:`, `chore:`, etc.
  (required by the `PULL_REQUEST_TEMPLATE.md` checklist).
- Versioning: SemVer on `platform-core/Chart.yaml`. Patch for bug fixes /
  version-pin bumps; minor for new features / new values; major for breaking.
- Weekly automated dependency bumps: GitHub Actions (Dependabot) and a
  `weekly-version-bump` gh-aw workflow (Fri 17:00 ET) that opens draft PRs
  titled `[version-bump] ` when upstream chart versions drift.

**Adding a new component (per `README.md` + `.github/agents/app-component.agent.md`)**
1. Create `platform-core/templates/argo-applications/<component>/<component>.yaml`.
2. Wrap the entire file in `{{- if .Values.bootstrap.<component>.enabled -}} … {{- end -}}`.
3. Add `bootstrap.<component>: { enabled: false, … }` default block in `values.yaml`
   with inline documentation.
4. Set `argocd.argoproj.io/sync-wave` based on dependency order
   (Gatekeeper `-120`, Gateway API `-115`, Crossplane `-112`, crossplane-config
   `-111`, crossplane-compositions `-109`, cert-manager `-107`, Istio `-100`,
   Prometheus `-90`, KEDA `-90`, NATS `-50` are the reference points).
5. Pin `targetRevision` to an exact chart version — never `latest`.
6. Apply Gatekeeper security context requirements on pods:
   `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,
   `capabilities.drop: [ALL]`, `seccompProfile.type: RuntimeDefault`.
7. Bump `platform-core/Chart.yaml` per SemVer.

**Custom Copilot agents (`.github/agents/`)**
- `app-component` — adding/upgrading components.
- `platform-engineer` — design/Helm/review tasks.
- `troubleshooter` — read-only diagnosis of Argo CD app failures via Kubernetes
  MCP tools; scoped to `cace-1-dev` context only.

## GitOps / deployment context

- The chart assumes Argo CD is already installed in the `argocd` namespace and
  that the chart is installed there too: `helm install platform-core ./platform-core -n argocd`.
- Every component renders an Argo CD `Application` (not raw workloads). Six
  `AppProject` boundaries group apps in `templates/argocd-projects.yaml`
  (`platform-foundations`, `platform-networking`, `platform-observability`,
  `platform-infra`, `platform-product-workspaces`, `platform-data`), all at
  sync-wave `-200`.
- Cluster identity comes from `global.clusterName` (default `"dev"`); it
  drives the host template (`*.{{ .Values.global.clusterName }}.dramisinfo.com`
  in `bootstrap.istio.host`) and resource naming (`rg-<clusterName>`,
  `umi-<clusterName>-certmanager`, etc.).
- `global.azure` holds tenant ID, subscription ID, and `canadacentral`
  default location; cert-manager UMI is provisioned via Crossplane
  (not Terraform) when `bootstrap.crossplane.certManagerIdentity.enabled = true`.
- `product-workspaces` AppProject discovers `XProductWorkspace` claims from
  `https://github.com/DramisInfo/*-workspace.git` repos via ApplicationSet.
- Cluster contexts the troubleshooter agent is authorised to investigate:
  `cace-1-dev` (`https://192.168.20.10:6443`); `cace-2-dev` is out of scope.
- Locked action versions live in `.github/aw/actions-lock.json`
  (`actions/github-script@v8`, `github/gh-aw-actions/setup@v0.62.5`).

## What NOT to do

- **Don't edit generated lock files.** `.gitattributes` marks
  `.github/workflows/*.lock.yml` as `linguist-generated=true merge=ours`; they
  are produced by `gh-aw` and any manual edits will be silently discarded on merge.
- **Don't widen the `hermes-sre-readonly` ClusterRole.** It is intentionally
  scoped to read-only pods/logs/events/nodes + ArgoCD/Crossplane resources.
  Never add `secrets`, write verbs, `pods/exec`, or `*` rules. Its token is
  meant to be handed to an autonomous agent sandbox.
- **Don't enable `bootstrap.terraformOperator` by default.** It is off by
  default (see commit `25a1433`) and must be opted into per cluster.
- **Don't change `bootstrap.gatekeeper.policies.enforcementAction` away from
  `deny` without first testing in `dryrun` mode** on the target cluster.
- **Don't pin `targetRevision` to `latest` or floating branches.** Pin exact
  chart versions (and exact commit SHAs for the gatekeeper-library source).
- **Don't bypass the chart to deploy workloads directly.** If something needs
  to exist on a cluster managed by this chart, it goes through a new Argo CD
  `Application` template and a `bootstrap.<component>.enabled` toggle.
- **Don't put secrets in `values.yaml`.** Use the External Secrets Operator
  (`bootstrap.externalSecretOperator.enabled`) and reference
  `akv-dramisinfo-shared` (`/subscriptions/.../vaults/akv-dramisinfo-shared`)
  via `bootstrap.crossplane.esoIdentity`. The Grafana README is explicit on this.
- **Don't investigate `cace-2-dev` from agent contexts.** The troubleshooter
  agent's RBAC and scope both exclude that cluster.
- **Don't skip SemVer or the PR checklist.** CI + `PULL_REQUEST_TEMPLATE.md`
  expect `helm lint`, `helm template`, comments-on-`values.yaml`, and a bumped
  `Chart.yaml` on every chart-affecting PR.

## Related repos

Cross-references found in this repo's manifests; not verified to exist:
- `DramisInfo/platform-crossplane-compositions` — Crossplane Compositions
  consumed by the `crossplane` Application (provider-xrd / composition chain).
- `DramisInfo/platform-project-workspaces` — discovers `XProductWorkspace`
  claims; source of `product-workspaces` AppProject's SCM ApplicationSet.
- `DramisInfo/*-workspace` — per-team workspace repos picked up by the
  ApplicationSet pattern (`*-workspace.git` glob in `argocd-projects.yaml`).
- `DramisInfo/platform-tools` — sibling namespace (`platform-tools`) referenced
  by `platform-infra` and `product-workspaces` AppProjects.

## Pointers

Files consulted to write this document:
- `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `LICENSE`
- `.gitattributes`, `.gitignore`
- `platform-core/Chart.yaml`, `platform-core/values.yaml`,
  `platform-core/README.md`, `platform-core/GATEKEEPER-POLICIES.md`,
  `platform-core/.helmignore`
- `platform-core/templates/_helpers.tpl`,
  `platform-core/templates/argocd-projects.yaml`,
  `platform-core/templates/platform-config.yaml`,
  `platform-core/templates/hermes-sre-rbac.yaml`
- `platform-core/templates/argo-applications/cert-manager/cert-manager.yaml`,
  `platform-core/templates/argo-applications/gatekeeper/gatekeeper.yaml`
- `.github/PULL_REQUEST_TEMPLATE.md`, `.github/dependabot.yml`
- `.github/workflows/helm-lint.yaml`, `.github/workflows/release.yaml`,
  `.github/workflows/test-chart-combinations.yaml`,
  `.github/workflows/weekly-version-bump.md`
- `.github/agents/app-component.agent.md`,
  `.github/agents/platform-engineer.agent.md`,
  `.github/agents/troubleshooter.agent.md`
- `.github/aw/actions-lock.json`
- `.github/prompts/add-component.prompt.md`,
  `.github/prompts/troubleshoot.prompt.md`,
  `.github/prompts/update-component.prompt.md`
- `.github/ISSUE_TEMPLATE/bug_report.md`,
  `.github/ISSUE_TEMPLATE/feature_request.md`