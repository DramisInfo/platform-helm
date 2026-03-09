# Platform Helm

**platform-core** is an open-source meta Helm chart that bootstraps shared platform components on Kubernetes clusters using a GitOps-first approach powered by [Argo CD](https://argo-cd.readthedocs.io/).

Rather than deploying workloads directly, every template renders an Argo CD `Application` CRD that points to an upstream Helm chart or Git repository. Argo CD then owns the full lifecycle of each component — upgrades, rollbacks, and drift detection — across one or more clusters.

---

## Table of Contents

- [Components](#components)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## Components

All components are opt-in and controlled through `values.yaml`. Enable only what your cluster needs.

| Component | Description | Default |
|---|---|:---:|
| [cert-manager](https://cert-manager.io/) | Automated TLS certificate management | disabled |
| [Crossplane](https://www.crossplane.io/) | Infrastructure provisioning via Kubernetes CRDs | disabled |
| [Terraform Operator](https://github.com/isaaguilar/terraform-operator) | Run Terraform workspaces from Kubernetes | disabled |
| [External Secrets Operator](https://external-secrets.io/) | Sync secrets from Vault, AWS SM, GCP SM, and more | disabled |
| [CNPG](https://cloudnative-pg.io/) | CloudNativePG — production-grade PostgreSQL on Kubernetes | disabled |
| [Atlas Operator](https://atlasgo.io/integrations/kubernetes) | Database schema migrations as Kubernetes resources | disabled |
| [Gatekeeper](https://open-policy-agent.github.io/gatekeeper/) | Policy enforcement via OPA with community library support | **enabled** |
| [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) | NGINX-based Kubernetes ingress controller | disabled |
| [Istio](https://istio.io/) | Service mesh with mTLS, traffic management, and observability | disabled |
| [Prometheus](https://prometheus.io/) | Metrics collection, alerting, and long-term storage | **enabled** |
| [Grafana](https://grafana.com/) | Metrics dashboards with plugin and datasource provisioning | **enabled** |
| [KEDA](https://keda.sh/) | Event-driven autoscaling for Kubernetes workloads | **enabled** |
| [NATS](https://nats.io/) | Cloud-native messaging with JetStream persistence | **enabled** |

---

## Prerequisites

- Kubernetes cluster (v1.24+)
- [Argo CD](https://argo-cd.readthedocs.io/en/stable/getting_started/) installed in the `argocd` namespace
- [Helm v3](https://helm.sh/docs/intro/install/)

---

## Getting Started

### 1. Install the chart

```bash
helm install platform-core ./platform-core \
  --namespace argocd \
  --values your-values.yaml
```

### 2. Upgrade an existing installation

```bash
helm upgrade platform-core ./platform-core \
  --namespace argocd \
  --values your-values.yaml
```

### 3. Minimal `values.yaml`

```yaml
global:
  clusterName: "my-cluster"   # used for resource naming and host templates

bootstrap:
  ingressNginx:
    enabled: true
  monitoring:
    enabled: true
  nats:
    enabled: true
  istio:
    enabled: true
```

Most components are disabled by default. See [platform-core/values.yaml](platform-core/values.yaml) for the full list of available options and inline documentation.

### 4. Validate before deploying

```bash
# Lint the chart
helm lint platform-core

# Render all templates to stdout
helm template platform-core ./platform-core

# Render with a custom values override
helm template platform-core ./platform-core -f my-values.yaml
```

---

## Repository Structure

```
platform-helm/
└── platform-core/                    # Main Helm chart
    ├── Chart.yaml
    ├── values.yaml                   # All component toggles and configuration
    ├── GATEKEEPER-POLICIES.md        # Enforced OPA policies and exclusions
    └── templates/
        └── argo-applications/        # One Argo CD Application per component
            ├── atlas/
            ├── cert-manager/
            ├── cnpg/
            ├── crossplane/
            ├── external-secret-operator/
            ├── gatekeeper/
            ├── grafana/
            ├── ingress-nginx/
            ├── istio/
            ├── keda/
            ├── nats/
            ├── prometheus/
            └── terraform-operator/
```

---

## Documentation

Refer to the inline comments in [platform-core/values.yaml](platform-core/values.yaml) and the following component-specific guides:

- [Gatekeeper Policies](platform-core/GATEKEEPER-POLICIES.md) — enforced constraints, exclusions, and enforcement modes
- [Grafana Configuration](platform-core/README.md) — plugin and datasource provisioning

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. For security issues, see [SECURITY.md](SECURITY.md).

When adding a new component:
1. Create `platform-core/templates/argo-applications/<component>/<component>.yaml`
2. Wrap the template with `{{- if .Values.bootstrap.<component>.enabled -}}`
3. Add the corresponding `enabled: false` default in `values.yaml` with inline comments
4. Choose an appropriate `argocd.argoproj.io/sync-wave` value based on dependency order

---

## License

This project is licensed under the [MIT License](LICENSE).
