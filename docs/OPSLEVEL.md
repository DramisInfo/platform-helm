# OpsLevel Integration

This directory contains ArgoCD Application manifests for deploying OpsLevel components to your Kubernetes cluster.

## Overview

OpsLevel is an AI-powered internal developer portal that automatically catalogs your software ecosystem, enforces engineering standards with scorecards and checks, and enables self-service actions for developers.

## Components

### 1. OpsLevel Application (`opslevel.yaml`)

The main OpsLevel application deployed via the official Helm chart from `registry.replicated.com`.

**Prerequisites:**
- Helm registry authentication credentials from OpsLevel
- External databases for production (MySQL, Postgres, Redis, Elasticsearch)

**Key Features:**
- Web application with optional ingress
- TLS support (inline certificates or existing secrets)
- Runner for async jobs (Repo Grep Checks, SBOM generation)
- Integration with external databases

### 2. OpsLevel Agent (`opslevel-agent.yaml`)

Kubernetes integration agent that syncs cluster resources to OpsLevel.

**Key Features:**
- Automatic service discovery from Kubernetes resources
- Configurable resource type targeting
- Multi-cluster support with integration aliases

## Configuration

### Enable OpsLevel

To enable OpsLevel components:

```yaml
bootstrap:
  opslevel:
    enabled: true
  opslevelAgent:
    enabled: true
```

### Default Configuration

The platform automatically configures:

- **Domain**: `opslevel-{clusterName}.dramisinfo.com` (e.g., `opslevel-dev.dramisinfo.com`)
- **Ingress**: Nginx with TLS enabled
- **TLS Certificate**: Managed by cert-manager via `vault-issuer`
- **Integration Alias**: Uses cluster name for multi-cluster identification

### Multi-Cluster Deployment

Each cluster automatically gets a unique integration alias based on `global.clusterName`:

**Dev Cluster (`values-dev.yaml`):**
```yaml
global:
  clusterName: "dev"

bootstrap:
  opslevelAgent:
    enabled: true
```

**Production Cluster (`values-prod.yaml`):**
```yaml
global:
  clusterName: "prod"

bootstrap:
  opslevelAgent:
    enabled: true
```

## Installation Steps

### 1. Helm Registry Login

Before deploying, authenticate with the OpsLevel Helm registry:

```bash
helm registry login registry.replicated.com --username YOUR_USERNAME --password YOUR_PASSWORD
```

### 2. Preflight Checks (Recommended)

Install the preflight utility:

```bash
curl https://krew.sh/preflight | bash
```

Run preflight checks:

```bash
helm template opslevel oci://registry.replicated.com/opslevel/helm/opslevel | kubectl preflight -
```

### 3. Deploy via ArgoCD

Update your `values.yaml` with the desired OpsLevel configuration and sync the platform-core chart:

```bash
# Update values.yaml with OpsLevel configuration
vim values.yaml

# Apply via ArgoCD
argocd app sync platform-core
```

## TLS Configuration

### Option 1: Using cert-manager (Recommended)

```yaml
bootstrap:
  opslevel:
    tls:
      enabled: true
      secret:
        create: false
        name: "opslevel-tls"
    ingress:
      enabled: true
      tls: true
      annotations:
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### Option 2: Inline Certificates

```yaml
bootstrap:
  opslevel:
    tls:
      enabled: true
      secret:
        create: true
        key: |
          -----BEGIN PRIVATE KEY-----
          ... your key content ...
          -----END PRIVATE KEY-----
        crt: |
          -----BEGIN CERTIFICATE-----
          ... your cert content ...
          -----END CERTIFICATE-----
```

## Kubernetes Service Mapping

The OpsLevel agent can automatically discover and map Kubernetes resources to services. You can customize this behavior using the `kubectl-opslevel` plugin.

### Install kubectl-opslevel

```bash
# macOS/Linux
brew install opslevel/tap/kubectl
```

### Generate Configuration Sample

```bash
kubectl opslevel config sample > opslevel-k8s.yaml
```

### Preview Service Mapping

```bash
export OL_APITOKEN=your-api-token
kubectl opslevel service preview -c opslevel-k8s.yaml
```

### Import Services

```bash
kubectl opslevel service import -c opslevel-k8s.yaml
```

## External Database Configuration (Optional)

While OpsLevel deploys with embedded databases by default, production deployments should use external managed databases. This requires manual customization of the ArgoCD Application manifest or using External Secrets Operator to inject credentials.

## Deployment Event Integration

### ArgoCD Integration

OpsLevel can automatically track deployments from ArgoCD using PostSync hooks. See the [ArgoCD integration docs](https://docs.opslevel.com/docs/argocd) for details.

### GitHub Actions Integration

Example workflow:

```yaml
- uses: OpsLevel/deploy-event-github-action@latest
  with:
    integration_url: ${{ secrets.OL_INTEGRATION_URL }}
    service: my-service
    environment: production
```

## Upgrading

To upgrade the OpsLevel installation:

```bash
helm upgrade --reuse-values opslevel oci://registry.replicated.com/opslevel/helm/opslevel
```

Or update the version in `values.yaml` and sync via ArgoCD.

## Troubleshooting

### Check Application Status

```bash
kubectl get applications -n argocd opslevel
kubectl get pods -n opslevel
```

### View Logs

```bash
kubectl logs -n opslevel -l app=opslevel
```

### Agent Logs

```bash
kubectl logs -n opslevel-agent -l app=opslevel-agent
```

## Resources

- [OpsLevel Self-Hosted Documentation](https://docs.opslevel.com/docs/getting-started-with-self-hosted-opslevel)
- [Kubernetes Integration Guide](https://docs.opslevel.com/docs/kubernetes-integration)
- [OpsLevel Agent Documentation](https://docs.opslevel.com/docs/opslevel-agent)
- [Helm Chart Repository](https://registry.replicated.com/opslevel/helm/opslevel)

## Security Considerations

1. **Secrets Management**: Consider using External Secrets Operator or similar tools instead of plain text secrets in values.yaml
2. **Database Security**: Ensure external databases have proper network policies and encryption
3. **API Tokens**: Rotate API tokens regularly
4. **RBAC**: The agent requires appropriate RBAC permissions to read Kubernetes resources
5. **TLS**: Always enable TLS in production environments

## License

Refer to OpsLevel's licensing terms for usage requirements.
