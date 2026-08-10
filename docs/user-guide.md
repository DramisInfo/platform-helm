# User guide

Day-to-day tasks for working with the `platform-core` chart: linting,
rendering, installing, configuring per-cluster overrides, common
operations, and troubleshooting.

## Prerequisites

- Helm v3 (CI pins `azure/setup-helm@v5` to `v3.14.4`).
- A Kubernetes cluster context.
- Argo CD already installed in the `argocd` namespace on the target
  cluster. The chart does not install Argo CD.
- A cluster-specific values file (see "Per-cluster values" below).

## Lint and render

Always lint and render before opening a PR or applying a change to a
running cluster:

```bash
helm lint platform-core
helm template platform-core ./platform-core                # defaults
helm template platform-core ./platform-core -f my-values.yaml
```

Lint catches schema, template, and `values.yaml` issues locally. Render
catches sync-wave ordering and reference problems that lint does not
see.

## Install

The chart installs into the `argocd` namespace alongside Argo CD:

```bash
helm install platform-core ./platform-core \
  -n argocd \
  -f my-values.yaml
```

To upgrade in place after a value change:

```bash
helm upgrade --install platform-core ./platform-core \
  -n argocd \
  -f my-values.yaml
```

After any change, confirm Argo CD picked up the rendered Applications
and that they reconcile in wave order.

## Per-cluster values

Keep cluster overrides in a values file under your platform-tools or
home-lab overlay (see [`related-repos.md`](related-repos.md)). A
typical cluster override looks like:

```yaml
global:
  clusterName: "cace-1-dev"

bootstrap:
  istio:
    host: "*.cace-1-dev.dramisinfo.com"

  gatekeeper:
    policies:
      # Start in dryrun while you validate new policies on this cluster.
      enforcementAction: dryrun
```

Common overrides:

| Concern                                  | Key                                                           |
| ---------------------------------------- | ------------------------------------------------------------- |
| Cluster name and Azure identity         | `global.clusterName`, `global.azure`                          |
| Per-cluster cert-manager UMI (via XP)    | `bootstrap.crossplane.certManagerIdentity.enabled`           |
| Per-cluster ESO UMI and ClusterSecretStore | `bootstrap.crossplane.esoIdentity`                         |
| Gatekeeper mode                          | `bootstrap.gatekeeper.policies.enforcementAction`             |
| Wildcard ingress host                    | `bootstrap.istio.host`                                        |
| Monitoring defaults                      | `bootstrap.monitoring.{grafana,loki,tempo}`                  |
| NATS JetStream domain / gateways         | `bootstrap.nats.jetstream`, `bootstrap.nats.gateway`         |
| Terraform Operator opt-in                | `bootstrap.terraformOperator.enabled`                        |

Never put credentials, tokens, or API keys in a values file. Use
External Secrets Operator against `akv-dramisinfo-shared` instead.

## Common operations

### Add a new platform component

1. Create `platform-core/templates/argo-applications/<component>/<component>.yaml`
   with the Argo CD `Application` manifest.
2. Wrap the file in `{{- if .Values.bootstrap.<component>.enabled -}}`
   so the toggle gates the render.
3. Add a default block `bootstrap.<component>: { enabled: false, ... }`
   in `values.yaml` with inline documentation.
4. Set `argocd.argoproj.io/sync-wave` based on dependency order
   (see [`architecture.md`](architecture.md) for reference points).
5. Pin `targetRevision` to an exact chart version or commit. Never
   `latest` or a floating branch.
6. Apply the required Gatekeeper security context to every pod:
   `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,
   `capabilities.drop: [ALL]`, `seccompProfile.type: RuntimeDefault`.
7. Add the component's destination namespace to the matching
   `AppProject` in `templates/argocd-projects.yaml`.
8. Bump `platform-core/Chart.yaml` per SemVer.

### Upgrade an upstream chart

1. Bump `targetRevision` in the relevant `templates/argo-applications/<component>/<component>.yaml`.
2. If the new chart has a breaking values schema, update the values
   passed via the template.
3. Run `helm lint platform-core` and `helm template platform-core
   ./platform-core -f my-values.yaml`.
4. Bump `platform-core/Chart.yaml` (patch for version pins, minor for
   a real chart upgrade).

### Switch Gatekeeper to dryrun for validation

```yaml
bootstrap:
  gatekeeper:
    policies:
      enforcementAction: dryrun
```

Apply, observe violations in Gatekeeper logs and audit events, then
flip back to `deny`.

### Enable the read-only agent SA

`bootstrap.hermesSre.enabled` is `false` by default. Set it to `true`
on clusters where you want a Hermes / agent sandbox to investigate
Argo CD and Crossplane status. Do not widen the resulting role.

## Troubleshooting

- **Helm reports an unknown `Application` kind.** Argo CD is not
  installed on the target cluster, or you installed into the wrong
  namespace. Install Argo CD into `argocd` and re-run `helm install`.
- **A component does not render.** Confirm the case-sensitive
  `bootstrap.<component>.enabled` key exists. Observability components
  share `bootstrap.monitoring.enabled` — Grafana, Loki, Tempo, and
  Beyla all flip with that one toggle.
- **An Application stays OutOfSync or unhealthy.** Inspect its
  AppProject, the pinned `targetRevision`, the destination namespace,
  and the sync-wave applications that must complete first (e.g.,
  Gateway API CRDs must land before cert-manager's Gateway API check,
  Crossplane must land before its compositions, and so on).
- **Gatekeeper blocks a new workload.** Add the required non-root
  security context, drop all capabilities, and use the
  `RuntimeDefault` seccomp profile. Validate in `dryrun` first.
- **First bootstrap fails on a missing CRD.** Re-sync in wave order:
  Gateway API → Crossplane → Crossplane compositions →
  cert-manager → Istio → Prometheus / KEDA → NATS.
- **Cert-manager DNS01 fails.** Confirm the cert-manager UMI was
  provisioned by Crossplane (`bootstrap.crossplane.certManagerIdentity.enabled`
  = true) and that Crossplane patched the cert-manager SA annotation.
  The chart's `workloadIdentity.clientId` is intentionally left empty
  for this reason.
- **Release artifacts not publishing.** Check
  `.github/workflows/release.yaml` and the chart-releaser
  configuration. Confirm `Chart.yaml` version was bumped.

## Contributing workflow

1. Branch off `main`: `feat/<short-name>` or `docs/<short-name>`.
2. Conventional Commit titles: `feat:`, `fix:`, `docs:`, `chore:`.
3. Run `helm lint platform-core` and `helm template platform-core
   ./platform-core` before pushing.
4. Update value comments where you change defaults.
5. Bump `platform-core/Chart.yaml` per SemVer for any chart-affecting
   change.
6. Open a PR back to `main`.

See [`CONTRIBUTING.md`](../CONTRIBUTING.md) and
[`PULL_REQUEST_TEMPLATE.md`](../.github/PULL_REQUEST_TEMPLATE.md) for
the full checklist.
