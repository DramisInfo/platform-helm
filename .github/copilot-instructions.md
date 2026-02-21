# Copilot Instructions — platform-helm

## Architecture Overview

`platform-core` is a **meta Helm chart**: it installs nothing directly. Instead, every template renders an Argo CD `Application` CRD that points to an upstream Helm chart or Git repo. Argo CD then manages the actual component lifecycle. All component templates live under `platform-core/templates/argo-applications/<component>/`.

The chart is deployed once into the `argocd` namespace and controlled entirely through `values.yaml`. Most components are opt-in (`enabled: false` by default).

## Key Structural Patterns

### Enabling/disabling components
Every template is wrapped with `{{- if .Values.bootstrap.<component>.enabled -}}`. To add a new component, follow this exact guard pattern and add a corresponding `enabled: false` default in `values.yaml` with inline comments.

### Multi-source ArgoCD Applications
Components frequently combine multiple sources in a single `Application`. The `dysnix/charts` `raw` chart is used to deploy arbitrary Kubernetes resources (CRDs, Gateways, Constraints) inline without a separate chart:
```yaml
sources:
  - repoURL: "https://upstream-helm-repo.example.com/charts"
    chart: my-chart
    targetRevision: "1.2.3"
    helm:
      valuesObject: { ... }
  - repoURL: "https://dysnix.github.io/charts"
    targetRevision: "0.3.2"
    chart: raw
    helm:
      valuesObject:
        resources:
          - apiVersion: some.crd.io/v1
            kind: SomeResource
            metadata:
              annotations:
                argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
```
Use `SkipDryRunOnMissingResource=true` whenever a resource depends on a CRD that may not yet exist at sync time.

### Sync wave ordering
Deployment order is controlled via `argocd.argoproj.io/sync-wave` on each Application. Current ordering (most negative = first):
- `-100` Gatekeeper (policies enforced before anything else)
- `-92` Prometheus
- `-80` Istio
- `-55` Grafana Operator
- `-40` NATS

When adding a new component, pick a sync wave value that reflects its dependency order.

### `global.clusterName` is pervasive
Used for resource naming, NATS cluster identity, and Istio host templating:
```yaml
host: "*.{{ .Values.global.clusterName }}.dramisinfo.com"
```
Always reference `{{ .Values.global.clusterName }}` rather than hardcoding cluster names.

### Gatekeeper policy compliance
All pod workloads (including those configured inside ArgoCD Applications) must satisfy Gatekeeper's pod security policies. Templates that configure upstream charts include explicit security contexts:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  seccompProfile:
    type: RuntimeDefault
```
See `platform-core/GATEKEEPER-POLICIES.md` for the full list of enforced constraints and excluded namespaces.

## Developer Workflows

```bash
# Lint the chart
helm lint platform-core

# Render all templates to stdout (primary debugging tool)
helm template platform-core ./platform-core

# Render with a specific values override
helm template platform-core ./platform-core -f my-values.yaml

# Install/upgrade against a live cluster
helm upgrade --install platform-core ./platform-core \
  --namespace argocd --values your-values.yaml
```

CI runs `helm lint` and `helm template` for several value combinations (minimal, full-stack, nats-gateway, etc.) on every PR — see `.github/workflows/ci.yaml`.

## Versioning & CI

- **Do not manually bump `platform-core/Chart.yaml` version** — CI auto-bumps it on merge to `main` using conventional commits.
- Commit prefix rules: `feat:` → minor bump, `feat!:` / `BREAKING CHANGE:` → major bump, everything else → patch.
- Add `[skip ci]` to a commit message to bypass the CI pipeline (used by the bot's version-bump commits).

## Adding a New Component

1. Create `platform-core/templates/argo-applications/<component>/<component>.yaml`
2. Wrap the entire file in `{{- if .Values.bootstrap.<newComponent>.enabled -}} ... {{- end }}`
3. Add `<newComponent>: enabled: false` under `bootstrap:` in `values.yaml` with comments
4. Pick an appropriate `argocd.argoproj.io/sync-wave` value
5. Use `helm template` to validate before pushing
