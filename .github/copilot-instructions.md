# Copilot Instructions for platform-helm

## Architecture

`platform-core` is a **meta Helm chart**: every template renders an Argo CD `Application` CRD — it never deploys workloads directly. Argo CD owns the full lifecycle (sync, upgrade, rollback, drift detection).

- All component templates live under `platform-core/templates/argo-applications/<component>/`
- Each component has its own subdirectory with one or more `Application` manifests
- Components and their upstream chart versions are declared inline inside each template (no sub-charts)
- All components are opt-in via `values.yaml` under `bootstrap.<component>.enabled`

## Adding a New Component

1. Create `platform-core/templates/argo-applications/<component>/<component>.yaml`
2. Wrap the entire file in `{{- if .Values.bootstrap.<component>.enabled -}} ... {{- end -}}`
3. Use `argocd.argoproj.io/sync-wave` annotations to control ordering (lower = earlier; Gatekeeper is `-100`, Prometheus `-92`, KEDA `-90`, NATS `-40`)
4. Set `namespace: argocd` on the `Application` metadata; set deployment namespace in `spec.destination.namespace`
5. Add the corresponding `enabled: false` toggle to `values.yaml` under `bootstrap`, with inline comments for all options
6. Bump `version` in `platform-core/Chart.yaml` (SemVer: patch for tweaks, minor for new features)

## Template Patterns

- Use `valuesObject:` (not `values:`) when passing Helm values inline inside an `Application` source — see [nats.yaml](../platform-core/templates/argo-applications/nats/nats.yaml) and [prometheus.yaml](../platform-core/templates/argo-applications/prometheus/prometheus.yaml)
- Use `{{- if .Values.bootstrap.<component>.<option> }}` guards before optional blocks
- Use `{{ .Values.global.clusterName | quote }}` for cluster-scoped names
- Multi-source apps (e.g., Gatekeeper + library) use `sources:` (list); single-source apps use `source:` (map) — see [gatekeeper.yaml](../platform-core/templates/argo-applications/gatekeeper/gatekeeper.yaml)
- All pod/container security contexts must comply with Gatekeeper policies: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile.type: RuntimeDefault` — see [keda.yaml](../platform-core/templates/argo-applications/keda/keda.yaml)
- Pin `targetRevision` to an exact chart version; do not use `latest` or floating tags

## Build and Validate

```bash
# Lint the chart
helm lint platform-core

# Render all templates (dry-run)
helm template platform-core ./platform-core

# Render with a custom values file
helm template platform-core ./platform-core -f my-values.yaml
```

CI runs `helm lint` and `helm template` on every PR automatically.

## Key Files

| File | Purpose |
|---|---|
| [platform-core/values.yaml](../platform-core/values.yaml) | All tuneable options with inline docs |
| [platform-core/Chart.yaml](../platform-core/Chart.yaml) | Chart version — bump on every change |
| [platform-core/GATEKEEPER-POLICIES.md](../platform-core/GATEKEEPER-POLICIES.md) | Policy details for OPA/Gatekeeper |
| [platform-core/README.md](../platform-core/README.md) | Grafana plugin/datasource provisioning guide |

## PR Conventions

- One feature or fix per PR; branch from `main` as `feat/<name>` or `fix/<name>`
- Update `values.yaml` comments when adding or changing options
- Always bump `version` in `Chart.yaml`
