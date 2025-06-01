# Platform Helm

A comprehensive Kubernetes platform deployment solution using Helm charts and ArgoCD for GitOps-based infrastructure management.

## Overview

This repository provides a unified platform deployment solution that packages and manages essential Kubernetes platform tools through Helm charts. It leverages ArgoCD for GitOps-style deployments and includes automated CI/CD workflows for continuous delivery.

## Architecture

The platform is built around a modular architecture with the following components:

### Core Components
- **platform-core**: Main Helm chart that orchestrates the entire platform
- **bootstrap**: Sub-chart that manages ArgoCD applications for individual platform components

### Platform Tools

The platform includes the following configurable tools:

| Tool | Description | Default Status |
|------|-------------|---------------|
| **Ingress NGINX** | Kubernetes ingress controller | ✅ Always enabled |
| **Cert-Manager** | TLS certificate management | ⚙️ Configurable |
| **Crossplane** | Cloud-native control plane | ⚙️ Configurable |
| **Atlas Operator** | Database schema management | ⚙️ Configurable |
| **Terraform Operator** | HashiCorp Terraform integration | ⚙️ Configurable |
| **External Secrets Operator** | External secret management | ⚙️ Configurable |
| **Prometheus** | Monitoring and alerting | ⚙️ Configurable |
| **Grafana** | Visualization and dashboards | ⚙️ Configurable |
| **Loki** | Log aggregation | ⚙️ Configurable |
| **NATS** | Cloud-native messaging system with JetStream | ⚙️ Configurable |

## Repository Structure

```
├── platform-core/              # Main Helm chart
│   ├── Chart.yaml              # Chart metadata and dependencies
│   ├── values.yaml             # Default configuration values
│   └── charts/bootstrap/       # Bootstrap sub-chart
│       ├── templates/
│       │   └── argo-applications/  # ArgoCD application templates
│       │       ├── atlas/
│       │       ├── cert-manager/
│       │       ├── crossplane/
│       │       ├── external-secret-operator/
│       │       ├── grafana/
│       │       ├── ingress-nginx/
│       │       ├── loki/
│       │       ├── nats/
│       │       ├── prometheus/
│       │       └── terraform-operator/
│       └── values.yaml         # Bootstrap configuration
├── .github/workflows/          # CI/CD automation
├── Taskfile.yml               # Task automation scripts
├── k3d-config.yaml           # K3d cluster configuration
├── kind-config.yaml          # Kind cluster configuration
└── argo-wait-apps.sh         # ArgoCD health monitoring script
```

## Quick Start

### Prerequisites

- Docker
- kubectl
- Helm 3.x
- Task (optional, for automation)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DramisInfo/platform-helm.git
   cd platform-helm
   ```

2. **Install dependencies and initialize cluster:**
   ```bash
   task init
   ```

3. **Access ArgoCD UI:**
   ```bash
   # Get admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   
   # Port forward to access UI
   kubectl port-forward service/argocd-server -n argocd 8080:443
   ```

   Navigate to https://localhost:8080 (username: `admin`)

## Configuration

### Enabling/Disabling Components

Modify `platform-core/values.yaml` to enable or disable specific platform components:

```yaml
global:
  clusterName: "dev"

bootstrap:
  crossplane:
    enabled: true
  atlas:
    enabled: false
  terraformOperator:
    enabled: true
  externalSecretOperator:
    enabled: true
  prometheus:
    enabled: true
  grafana:
    enabled: true
  loki:
    enabled: false
  nats:
    enabled: true
```

### Domain Configuration

The platform supports automatic TLS certificate management through cert-manager with Let's Encrypt. Configure your domain in the cluster issuer template.

### Git Tag-based Versioning

The platform uses git tags for version management instead of OCI registries. ArgoCD applications can reference specific versions using git tags:

**For Development:**
```yaml
source:
  repoURL: "https://github.com/DramisInfo/platform-helm.git"
  targetRevision: "HEAD"  # Always use latest
  path: platform-core
```

**For Production:**
```yaml
source:
  repoURL: "https://github.com/DramisInfo/platform-helm.git"
  targetRevision: "v0.2.51"  # Pin to specific version
  path: platform-core
```

**Available versions** can be viewed via:
```bash
git tag -l "v*"
# or check GitHub releases
```

## Automation

### Available Tasks

The repository includes automated tasks via [Task](https://taskfile.dev/):

| Task | Description |
|------|-------------|
| `task init` | Complete initialization (recommended for first-time setup) |
| `task ci` | Run full CI pipeline |
| `task create-cluster` | Create local Kubernetes cluster (k3d) |
| `task delete-cluster` | Delete local cluster |
| `task helm-lint` | Lint Helm charts |
| `task argocd-install` | Install ArgoCD |
| `task wait-for-argo-apps` | Wait for all applications to be healthy |

### CI/CD Pipeline

The repository includes a comprehensive CI/CD pipeline with:

1. **Testing Phase**: 
   - Helm chart linting
   - Local cluster creation and testing
   - ArgoCD application deployment validation

2. **Release Phase**:
   - Automated Helm chart packaging
   - Git tag creation for version management
   - Semantic versioning with conventional commits

3. **Deployment Phase**:
   - Automatic updates to downstream platform-tools repository with git tag references
   - GitOps-style deployment to target clusters

## Cluster Compatibility

The platform supports multiple Kubernetes distributions:

- **k3d** (recommended for local development)
- **Kind** (alternative local development)
- **Standard Kubernetes** clusters (cloud providers)

Configuration files are provided for each:
- `k3d-config.yaml`: K3d cluster with Traefik disabled
- `kind-config.yaml`: Multi-node Kind cluster

## Monitoring and Observability

When enabled, the platform provides a complete observability stack:

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization with pre-configured dashboards
- **Loki**: Log aggregation and querying

All components are configured with:
- Automatic service discovery
- TLS encryption
- Domain-based ingress access

## Development

### Local Development Workflow

1. Make changes to Helm charts
2. Run `task helm-lint` to validate
3. Test with `task init` for full local deployment
4. Commit changes using conventional commit format
5. CI/CD pipeline handles testing and release

### Version Management

- Uses semantic versioning with conventional commits
- Automated version bumping via semantic-release
- Chart versions are automatically updated during releases
- Git tags are used for release management instead of container registries
- ArgoCD applications reference specific git tags for stable deployments

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes following conventional commit format
4. Test locally using provided tasks
5. Submit a pull request

## License

This project follows the standard Helm chart licensing model.

## Support

For issues and questions:
- Check existing GitHub issues
- Create new issues with detailed descriptions
- Include logs and configuration when reporting problems
