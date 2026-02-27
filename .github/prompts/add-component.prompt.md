---
name: add-component
description: Add new components to the platform-core meta Helm chart as Argo CD Application manifests.
agent: app-component
---
# Add a New Component to platform-core

You are helping a user add a new component to the platform-core meta Helm chart.

## Context
- platform-core is a meta Helm chart that renders Argo CD Application CRDs
- Each component lives in `platform-core/templates/argo-applications/<component>/`
- All components are opt-in via `values.yaml` under `bootstrap.<component>.enabled`

## Task
Guide the user through:

1. **Component Details**: Ask for the component name, upstream chart repo, and target version
2. **Configuration**: Determine if the component needs custom values passed via `valuesObject:`
3. **Sync Wave**: Suggest an appropriate `argocd.argoproj.io/sync-wave` annotation (lower numbers = earlier execution)
4. **Generate Manifest**: Create the Application YAML template following the architecture guidelines
5. **Update values.yaml**: Add the `enabled: false` toggle under `bootstrap` with inline documentation
6. **Bump Version**: Remind to increment `platform-core/Chart.yaml` version (SemVer)
7. **Validate**: Run `helm lint` and `helm template` to verify

## Constraints
- Wrap entire template in `{{- if .Values.bootstrap.<component>.enabled -}} ... {{- end -}}`
- Set `namespace: argocd` on Application metadata; deployment namespace in `spec.destination.namespace`
- Pin `targetRevision` to exact chart version (no floating tags)
- Ensure all pod/container security contexts comply with Gatekeeper policies
- For multi-source apps (e.g., library + chart), use `sources:` list; otherwise use `source:` map