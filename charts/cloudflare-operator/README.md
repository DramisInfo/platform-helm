# cloudflare-operator Helm chart

Charts the [adyanth/cloudflare-operator](https://github.com/adyanth/cloudflare-operator)
v0.13.1 — a Kubernetes operator that exposes Cloudflare Tunnel / DNSRecord /
CloudflareTunnel CRDs.

## Why this exists

`community-charts/cloudflared` (DaemonSet pattern, single tunnel, multi-ingress
via values) is the right choice when you want 1 shared tunnel across the cluster.

`adyanth/cloudflare-operator` is the right choice when you want **per-service
Tunnel CRDs** declared in your workspace repos, with each service owning its
own ingress rules, DNS records, and lifecycle.

## What's in this chart

- `Namespace/cloudflare-operator-system` (via this chart)
- `ServiceAccount/cloudflare-operator`
- `ConfigMap/cloudflare-operator-config` (account + zone IDs)
- `ExternalSecret/cloudflare-operator-api-token` (synced from AKV)
- `ClusterRole` + `ClusterRoleBinding` (Tunnel/TunnelDNSRecord/CloudflareTunnel CRDs)
- `Deployment/cloudflare-operator` (1 replica, leader-elect)

## What's NOT in this chart

- **CRDs are NOT installed by the chart.** Apply them separately via Argo CD
  raw resource pointing at `https://github.com/adyanth/cloudflare-operator/releases/download/v<version>/cloudflare-operator.crds.yaml`
  at sync-wave -130 (before the operator deploys at -90).
- **Tunnels are NOT created by the chart.** You write your own `Tunnel` /
  `TunnelDNSRecord` CRDs in workspace repos.

## Activation prerequisites

1. AKV secret `cloudflare-api-token` with:
   - `Zone:DNS:Edit`
   - `Account:Cloudflare Tunnel:Edit`
   - `Account:Account Settings:Read`
2. Cloudflare account ID (ConfigMap value, set via overlay patch)
3. CRDs installed (handled by Argo CD raw resource)
4. (Later) Per-service Tunnel CRDs declared in workspace repos

## Versioning

- `version` (chart) — bump by hand on breaking changes
- `appVersion` — bumped by `chore/version-bump-*` workflow
