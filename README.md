# platform-helm

This repository contains the **platform-core** Helm chart — a meta-chart that manages the bootstrapping of shared platform components on Kubernetes clusters via [Argo CD](https://argo-cd.readthedocs.io/).

Each component is deployed as an Argo CD `Application`, allowing GitOps-driven lifecycle management across one or more clusters.

## Components

The following platform components can be enabled or disabled through `values.yaml`:

| Component | Description |
|---|---|
| [cert-manager](https://cert-manager.io/) | TLS certificate management |
| [Crossplane](https://www.crossplane.io/) | Infrastructure provisioning via Kubernetes |
| [Terraform Operator](https://github.com/isaaguilar/terraform-operator) | Run Terraform from Kubernetes |
| [External Secrets Operator](https://external-secrets.io/) | Sync secrets from external providers |
| [CNPG](https://cloudnative-pg.io/) | CloudNativePG PostgreSQL operator |
| [Gatekeeper](https://open-policy-agent.github.io/gatekeeper/) | Policy enforcement via OPA |
| [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) | Ingress controller |
| [Istio](https://istio.io/) | Service mesh |
| [Prometheus](https://prometheus.io/) | Metrics collection and alerting |
| [Grafana](https://grafana.com/) | Metrics visualization |
| [KEDA](https://keda.sh/) | Event-driven autoscaling |
| [NATS](https://nats.io/) | Messaging system with JetStream |

## Prerequisites

- Kubernetes cluster
- Argo CD installed and configured
- Helm v3

## Usage

### Install via Helm

```bash
helm install platform-core ./platform-core \
  --namespace argocd \
  --values your-values.yaml
```

### Minimal `values.yaml`

```yaml
global:
  clusterName: "my-cluster"

bootstrap:
  ingressNginx:
    enabled: true
  monitoring:
    enabled: true
  nats:
    enabled: true
  istio:
    enabled: true
    host: "*.my-cluster.example.com"
```

Most components are disabled by default and must be explicitly enabled. See [platform-core/values.yaml](platform-core/values.yaml) for all available options.

## Repository Structure

```
platform-helm/
└── platform-core/          # Main Helm chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        └── argo-applications/   # One Argo CD Application per component
```

## Documentation

> A detailed documentation section covering configuration, multi-cluster setup, policy management, and component-specific guides is coming soon.

In the meantime, refer to the inline comments in [platform-core/values.yaml](platform-core/values.yaml) and the component-specific notes:

- [Gatekeeper Policies](platform-core/GATEKEEPER-POLICIES.md)
- [Grafana Configuration](platform-core/README.md)


## License

See [LICENSE](LICENSE) if present, or contact the maintainers.
