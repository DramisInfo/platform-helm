---
name: update-component
description: Update existing component with latest version of upstream Helm chart and reconcile values.
agent: app-component
---
# Update Component Task

You are updating an existing component in the `platform-helm` repository.

## Steps

1. **Identify the component** from user input (e.g., `prometheus`, `nats`, `keda`)

2. **Check the current version** in `platform-core/templates/argo-applications/<component>/<component>.yaml`

3. **Find the latest upstream Helm chart version** using the Helm CLI:
   ```bash
   # Add the upstream repo if not already added
   helm repo add <repo-name> <repo-url>
   helm repo update

   # List available versions (latest first)
   helm search repo <repo-name>/<chart-name> --versions | head -10
   ```

4. **Review the upstream chart values** for the new version before making changes:
   ```bash
   # Inspect default values for the new version
   helm show values <repo-name>/<chart-name> --version <new-version>

   # Inspect chart metadata and dependencies
   helm show chart <repo-name>/<chart-name> --version <new-version>
   ```

5. **Update the `targetRevision`** in the Application manifest to the new exact chart version

6. **Review and reconcile `valuesObject`** — compare the new chart's default values against the current `valuesObject:` block; add/remove/modify keys to match the new chart's API

7. **Verify Gatekeeper compliance** — ensure all security contexts are present if applicable (`runAsNonRoot`, `allowPrivilegeEscalation`, `capabilities.drop`, `seccompProfile`)

8. **Bump the patch version** in `platform-core/Chart.yaml`

9. **Validate** with the Helm CLI:
   ```bash
   # Lint the chart for errors
   helm lint platform-core

   # Dry-run render all templates
   helm template platform-core ./platform-core

   # Render with a custom values file if needed
   helm template platform-core ./platform-core -f my-values.yaml
   ```

10. **Output** the updated manifest and summary of changes

Only proceed if the user confirms the component name and new version.