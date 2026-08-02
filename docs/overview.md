# Overview

`platform-helm` ships a single meta Helm chart, `platform-core`, that
bootstraps a Kubernetes cluster's platform layer as Argo CD
`Application` CRDs rather than as direct workloads. Argo CD owns the
full lifecycle (install, upgrade, rollback, drift detection, prune,
self-heal) of every component the chart enables.

## What this repo contains

```
platform-helm/
├── platform-core/                       the chart
│   ├── Chart.yaml                       chart metadata (SemVer version)
│   ├── values.yaml                      bootstrap.* toggles + cluster identity
│   ├── README.md                        Grafana-specific value docs
│   ├── GATEKEEPER-POLICIES.md           policy library behaviour, exclusions
│   └── templates/
│       ├── _helpers.tpl                 retry helpers
│       ├── argocd-projects.yaml         six platform AppProjects
│       ├── platform-config.yaml         shared cluster identity ConfigMap
│       ├── hermes-sre-rbac.yaml         read-only SA for agent investigation
│       └── argo-applications/<comp>/    one Argo CD Application per component
├── .github/                             CI, release automation, agents, prompts
├── README.md                            user-facing entry point
└── CONTRIBUTING.md, SECURITY.md, LICENSE
```

The chart currently renders Argo CD Applications for, among others:
Gateway API, Gatekeeper (with policy library), cert-manager,
Crossplane, External Secrets Operator, Istio, Envoy Gateway, KEDA,
NATS (with JetStream and optional gateway mesh), Argo Events, Atlas
Operator, CloudNative-PG, Grafana, Loki, Tempo, Prometheus, Beyla,
k6 Operator, KubeVela, and the Terraform Operator.

## Who uses this repo

- Platform engineers maintaining the DramisInfo platform stack.
- Application teams that consume the resulting platform layer
  (ingress, mesh, secrets, observability, data services) on their
  product workspaces.
- Operators bringing up a new cluster who need a known-good
  composition of platform components.

## When to touch it

Touch this repo when you need to:

- Add, remove, or upgrade a platform component.
- Change the default `bootstrap.<component>.enabled` toggle for a new
  cluster baseline.
- Tune cluster identity (`global.clusterName`, `global.azure`),
  ingress hosts (`bootstrap.istio.host`), Gatekeeper policy
  enforcement, monitoring defaults, or NATS / JetStream settings.
- Adjust sync-wave ordering between components (e.g., when adding a
  new CRD-providing application that must land before its
  dependents).
- Update pinned upstream chart or source revisions.

Do not touch this repo to deploy application workloads directly. All
workloads — platform or product — belong behind an Argo CD
`Application`. New platform capabilities go in as new component
templates under `templates/argo-applications/<component>/` with a
matching `bootstrap.<component>.enabled` toggle.

## When not to touch it

- Cluster bootstrap, Proxmox, Azure Arc registration: handled by
  `DramisInfo/home-lab`.
- Crossplane Compositions and XRDs: handled by
  `DramisInfo/platform-crossplane-compositions`.
- Crossplane providers and functions: handled by
  `DramisInfo/crossplane-providers-and-functions`.
- Per-project tenant workspaces, RBAC, quotas, and ApplicationSets:
  handled by `DramisInfo/platform-project-workspaces`.
- Repo-wide conventions and policy documents: handled by
  `DramisInfo/platform-standards`.
- Shared CI workflows: handled by `DramisInfo/platform-workflows`.

See [`related-repos.md`](related-repos.md) for the full list.

## Release and versioning

The chart follows SemVer on `platform-core/Chart.yaml`. Patch bumps
for bug fixes and version-pin refreshes; minor bumps for new
components, new value toggles, or non-breaking chart upgrades; major
bumps for breaking changes. Releases are automated by
release-please (`.github/workflows/release-please.yml`) and published
as GitHub Releases with packaged chart artifacts by the chart-releaser
workflow (`.github/workflows/release.yaml`).
