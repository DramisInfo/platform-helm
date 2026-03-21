---
description: 'Daily scan of platform-core ArgoCD applications to check for newer helm chart versions and create a PR with updated versions'
on:
  schedule: daily
  workflow_dispatch: {}
permissions:
  contents: read
  pull-requests: read
tools:
  github:
    toolsets: [repos, pull_requests]
    mode: remote
    toolsets: [repos, issues, pull_requests]
    github-app:
      app-id: ${{ vars.APP_ID }}
      private-key: ${{ secrets.APP_PRIVATE_KEY }}
safe-outputs:
  create-pull-request:
    base-branch: main
    title-prefix: "chore(deps): "
    draft: false
  noop:
---

# Helm Chart Version Check Agent

You are an automated agent responsible for keeping the platform-core Helm chart dependencies up to date. The `platform-core` chart is a meta Helm chart that deploys platform components as Argo CD Applications. Each Argo CD application references external Helm chart repositories with specific versions.

## Your Task

Perform a daily scan of all Argo CD Application manifests in `platform-core/templates/argo-applications/` to:

1. Identify all Helm charts being used and their current versions
2. Query each Helm repository to find the latest stable version
3. Determine if any updates are available
4. Validate if the new chart version requires any values or configuration changes
5. If updates are found, create a single Pull Request with all version bumps and any required adjustments

## Step 1: Discover All ArgoCD Applications

Read all YAML files in `platform-core/templates/argo-applications/` recursively. For each file, extract:
- Application name (from `metadata.name`)
- Whether it uses a Helm chart source (has a `chart:` field alongside `repoURL:`)
- Helm repository URL (`repoURL`)
- Chart name (`chart`)
- Current version (`targetRevision`)

**Also check** `platform-core/values.yaml` for version references:
- `bootstrap.gatewayAPI.targetRevision` — controls the Gateway API CRDs version

**Skip** the following (no versioning action needed):
- Applications with `targetRevision: HEAD` (Git-branch-pinned, no semantic versioning)
- Applications with `targetRevision: master` or `targetRevision: main` (branch-pinned)
- Any `repoURL` starting with `https://github.com/DramisInfo/` (internal Git repositories)
- The `raw` utility chart from `https://dysnix.github.io/charts` — this is a Kubernetes manifest helper chart, do not update it

## Step 2: Query Latest Versions

For each identified Helm chart, query the repository for the latest stable version.

### Standard HTTPS Helm Repositories

The recommended approach is to use the Helm CLI (pre-installed on GitHub Actions runners), which handles version sorting correctly:

```bash
helm repo add <alias> <repo_url> --force-update 2>/dev/null
helm search repo <alias>/<chart_name> --output json | \
  python3 -c "import sys,json; data=json.load(sys.stdin); print(data[0]['version']) if data else print('not found')"
```

Alternatively, fetch the repository index directly and use `packaging` for robust semver sorting:

```bash
pip install packaging -q 2>/dev/null
curl -s "<repo_url>/index.yaml" | \
  python3 -c "
import sys, yaml
from packaging.version import Version, InvalidVersion
d = yaml.safe_load(sys.stdin)
entries = d.get('entries', {}).get('<chart_name>', [])
stable = []
for e in entries:
    try:
        v = Version(e['version'].lstrip('v'))
        if not v.is_prerelease and not v.is_devrelease:
            stable.append(e['version'])
    except InvalidVersion:
        pass
print(sorted(stable, key=lambda v: Version(v.lstrip('v')))[-1] if stable else 'not found')
"
```

### OCI Helm Registries

For charts like `oci://ghcr.io/ariga/charts/atlas-operator`, use helm directly (most reliable for OCI):

```bash
# Pull the latest chart info from OCI registry (public access, no auth required for public images)
helm show chart oci://ghcr.io/ariga/charts/atlas-operator 2>/dev/null | \
  grep "^version:" | awk '{print $2}'
```

If `helm show chart` without a version returns the latest chart version, use that value.

### Istio (Google Cloud Storage)

Istio releases are hosted at `https://istio-release.storage.googleapis.com/charts`. Use helm for reliability:

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts --force-update 2>/dev/null
helm search repo istio/base --output json | \
  python3 -c "import sys,json; data=json.load(sys.stdin); print(data[0]['version']) if data else print('not found')"
```

### Gateway API (GitHub Releases)

The Gateway API CRDs use GitHub releases. Check for the latest tag:

```bash
curl -s "https://api.github.com/repos/kubernetes-sigs/gateway-api/releases/latest" \
  -H "Authorization: token $GITHUB_TOKEN" | \
  python3 -c "import sys,json; data=json.load(sys.stdin); print(data['tag_name'])"
```

## Step 3: Compare Versions and Build Update List

For each chart, compare the current `targetRevision` with the latest available version.

Rules:
- Use semantic versioning comparison (ignore `v` prefix when comparing: `v1.16.2` = `1.16.2`)
- Only flag as needing update if the latest version is genuinely newer (not just a different format)
- Ignore pre-release versions (alpha, beta, rc) unless the current version is also a pre-release
- Maintain the same version prefix style: if current is `v1.16.2`, update to `v1.17.0` (not `1.17.0`)

Build a list of updates: `{appFile, chart, repoURL, currentVersion, latestVersion, versionLocation}`

Where `versionLocation` is one of:
- Path to the template file where `targetRevision` is hardcoded (e.g., `platform-core/templates/argo-applications/keda/keda.yaml`)
- `platform-core/values.yaml` with the YAML path (e.g., `bootstrap.gatewayAPI.targetRevision`)

## Step 4: Validate Values Compatibility

For each chart that has an update available, assess if values changes are needed:

1. **Fetch default values diff**: Compare `helm show values <repo>/<chart> --version <oldVersion>` vs `--version <newVersion>`
2. **Check release notes**: Look for a GitHub releases page or CHANGELOG for the chart's repository noting breaking changes
3. **Inspect inline values**: In the ArgoCD Application YAML, look for `values:` blocks. Cross-reference the keys used against the new chart's expected values schema

Document in the PR description:
- Any new required values introduced in the new version
- Any removed or renamed values keys
- Any behavioral changes that require configuration updates

## Step 5: Apply Updates

If **no updates are needed**, call the `noop` safe output with a message like:
> "All helm charts are up to date. Checked N charts across M applications."

If updates are available:

### Updating Hardcoded Template Versions

Edit the ArgoCD Application YAML file to change the `targetRevision` value. Example:

```yaml
# Before
targetRevision: "2.19.0"
# After
targetRevision: "2.20.0"
```

For **multi-source applications** (those with a `sources:` list instead of `source:`), identify the correct source by matching both `repoURL` and `chart`, then update only that source's `targetRevision`.

### Updating values.yaml References

For the Gateway API CRDs (stored in `platform-core/values.yaml`):

```yaml
# Before
gatewayAPI:
  enabled: true
  targetRevision: "v1.2.1"
# After
gatewayAPI:
  enabled: true
  targetRevision: "v1.3.0"
```

### Istio Multi-Chart Update

Istio uses 4 separate ArgoCD Application sources (`base`, `istiod`, `cni`, `ztunnel`), all pinned to the same version. When updating Istio, update **all 4 sources** to the same new version in `platform-core/templates/argo-applications/istio/istio.yaml`.

## Step 6: Create Pull Request

After making all version updates, create a pull request using the `create-pull-request` safe output.

**PR Title**: `chore(deps): update helm chart versions [automated]`

**PR Body** must include:

1. A summary table of all updates:
   ```
   | Application | Chart | Repository | Old Version | New Version |
   |------------|-------|------------|-------------|-------------|
   | keda | keda | kedacore.github.io | 2.19.0 | 2.20.0 |
   ```

2. A "Values Changes Required" section (if any) listing charts where manual review is needed:
   ```
   ## ⚠️ Values Changes Required

   ### kube-prometheus-stack (69.2.0 → 70.0.0)
   - New value `grafana.sidecar.enableUniqueFilenames` added (default: false)
   - Value `prometheus.prometheusSpec.retentionSize` format changed
   ```

3. A "No Values Changes Detected" note for clean updates.

4. Testing instructions:
   ```
   ## Testing
   1. Run `helm lint platform-core` to validate the chart renders
   2. Review any values changes noted above against the current `platform-core/values.yaml`
   3. Test in a development cluster before merging
   ```

## Reference: Applications and Their Repositories

| Application File | Chart | Helm Repo URL | Notes |
|-----------------|-------|---------------|-------|
| cert-manager/cert-manager.yaml | cert-manager | https://charts.jetstack.io | |
| crossplane/crossplane.yaml | crossplane | https://charts.crossplane.io/stable | |
| terraform-operator/terraform-operator.yaml | hcp-terraform-operator | https://helm.releases.hashicorp.com | |
| external-secret-operator/eso.yaml | external-secrets | https://charts.external-secrets.io | |
| cnpg/cnpg.yaml | cloudnative-pg | https://cloudnative-pg.github.io/charts | |
| argo-events/argo-events.yaml | argo-events | https://argoproj.github.io/argo-helm | |
| tempo/tempo.yaml | tempo | https://grafana.github.io/helm-charts | |
| prometheus/prometheus.yaml | kube-prometheus-stack | https://prometheus-community.github.io/helm-charts | |
| beyla/beyla.yaml | beyla | https://grafana.github.io/helm-charts | Multi-source |
| loki/loki.yaml | loki | https://grafana.github.io/helm-charts | Multi-source |
| loki/loki.yaml | alloy | https://grafana.github.io/helm-charts | Multi-source |
| grafana/grafana-operator.yaml | grafana-operator | https://grafana.github.io/helm-charts | |
| gatekeeper/gatekeeper.yaml | gatekeeper | https://open-policy-agent.github.io/gatekeeper/charts | Multi-source |
| keda/keda.yaml | keda | https://kedacore.github.io/charts | |
| k6-operator/k6-operator.yaml | k6-operator | https://grafana.github.io/helm-charts | |
| nats/nats.yaml | nats | https://nats-io.github.io/k8s/helm/charts/ | Multi-source |
| nats/nack.yaml | nack | https://nats-io.github.io/k8s/helm/charts/ | |
| istio/istio.yaml | base, istiod, cni, ztunnel | https://istio-release.storage.googleapis.com/charts | 4 sources, same version |
| envoy-gateway/envoy-gateway.yaml | gateway-helm | docker.io/envoyproxy (OCI) | Multi-source |
| atlas/atlas.yaml | atlas-operator | oci://ghcr.io/ariga/charts | OCI registry |
| kubevela/kubevela.yaml | vela-core | https://kubevela.github.io/charts | |
| gateway-api/gateway-api.yaml | (GitHub release) | https://github.com/kubernetes-sigs/gateway-api | Version in values.yaml |

## Important Notes

1. **Helm lint validation**: After making changes, you can optionally run `helm lint platform-core` to ensure the chart still renders correctly before creating the PR.

2. **Conditional Helm template blocks**: Many templates wrap the `targetRevision` inside `{{- if ... }}` blocks. When searching for version strings to update, make sure to find ALL occurrences of a version for a given chart in a file.

3. **Version prefix consistency**: If the current version uses a `v` prefix (e.g., `v1.16.2`), the updated version should also use the `v` prefix (e.g., `v1.17.0`). If no prefix, keep without prefix.

4. **OCI chart versions**: For atlas-operator (OCI), verify the version format used. Some OCI charts use semver without `v` prefix.

5. **Istio version uniformity**: Always update all 4 Istio components (base, istiod, cni, ztunnel) to the same version simultaneously. Never update them independently.

6. **PR labels**: If the labels `dependencies` and `automated` exist in the repository, add them to the PR. If they don't exist, omit labels.

7. **Existing open PRs**: Before creating a new PR, check if there's already an open PR with the title prefix `chore(deps): update helm chart versions`. If one exists, use `noop` and note that an existing PR is already open.
