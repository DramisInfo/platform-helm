# cloudflare-operator Helm chart

Opt-in Helm chart for the [adyanth/cloudflare-operator](https://github.com/adyanth/cloudflare-operator),
declared as a platform component and gated by `bootstrap.cloudflareOperator.enabled`
in `platform-core/values.yaml`.

## Why opt-in (off by default)

This operator manages CloudflareTunnel / TunnelDNSRecord / CloudflareTunnel CRDs
declaratively. It is intentionally not enabled in `platform-core` defaults:

- It requires a Cloudflare API token (provisioned externally via Terraform
  into AKV `cloudflare-api-token`).
- It introduces a Cloudflare Tunnel into the cluster — a behavior change
  other workspaces do not depend on.
- The Cloudflare project ships no official K8s operator — this is
  `adyanth/cloudflare-operator` (community, 661 stars, 2023→).

Activate per-cluster via overlay patch once a use case justifies it (e.g.
`platform-tools/overlays/cace-1-dev/platform-core.yaml` patch).

## CRDs installed

- `Tunnel` (`networking.cloudflare-operator.dev/v1`)
- `CloudflareTunnel` (`networking.cloudflare-operator.dev/v1`)
- `TunnelDNSRecord` (`networking.cloudflare-operator.dev/v1`)

## Used by

- `it-pme-atelier-workspace` (planned) — expose Composio webhook
  ingress to cluster pods.

## Versioning

- `version` (chart): bumped by hand on breaking changes.
- `appVersion` (operator image): bumped by the version-bump workflow
  (`chore/version-bump-*` branches in repo).
