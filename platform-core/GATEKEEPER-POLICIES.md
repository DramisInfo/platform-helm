# Gatekeeper Policies

This chart integrates the official [OPA Gatekeeper Policy Library](https://github.com/open-policy-agent/gatekeeper-library) for Kubernetes security policies.

## Overview

Instead of maintaining custom policy definitions, we leverage the community-maintained Gatekeeper Library that provides:
- Pre-built, tested ConstraintTemplates
- CIS Kubernetes Benchmark compliance
- Active maintenance and updates
- Comprehensive policy coverage

## Architecture

```
ArgoCD Application (policies.yaml)
    └─> Gatekeeper Library (GitHub)
         └─> Pod Security Policy ConstraintTemplates

Helm Chart Constraints (templates/gatekeeper-constraints/)
    ├── privileged-container.yaml
    └── run-as-nonroot.yaml
```

The ConstraintTemplates come from the library, but the Constraint instances are managed in your Helm chart for version control and environment-specific configuration.

## Deployed Policies

### 1. Block Privileged Containers (CIS 5.2.1)
**Constraint**: `psp-privileged-container`
**Template**: From library - `K8sPSPPrivilegedContainer`

Prevents containers from running in privileged mode.

### 2. Enforce Non-Root Users (CIS 5.2.6)
**Constraint**: `psp-pods-must-run-as-nonroot`
**Template**: From library - `K8sPSPAllowedUsers`

Requires all containers to run as non-root users.

## Configuration

Configure policies via Helm values:

```yaml
bootstrap:
  gatekeeper:
    enabled: true      # Deploy Gatekeeper
    policies:
      enabled: true    # Deploy policies from library
      enforcementAction: deny  # deny (default) or dryrun
      excludedNamespaces:
        - kube-system
        - gatekeeper-system
        - cert-manager
        - istio-system
        - argocd
      exemptImages: []  # List of image patterns to exempt
```

## Adding New Policies

The library includes 30+ additional policies. To add more:

1. Check available policies: https://open-policy-agent.github.io/gatekeeper-library/
2. Create a new Constraint in `templates/gatekeeper-constraints/`
3. Reference the appropriate ConstraintTemplate kind from the library
4. Configure namespace exclusions and parameters

Example - adding a required labels policy:
```yaml
{{- if and .Values.bootstrap.gatekeeper.enabled .Values.bootstrap.gatekeeper.policies.enabled -}}
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-app-label
  annotations:
    argocd.argoproj.io/sync-wave: "20"
spec:
  enforcementAction: {{ .Values.bootstrap.gatekeeper.policies.enforcementAction | default "deny" }}
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    labels:
      - key: "app"
{{- end -}}
```

## Testing

Test policies locally with Helm:
```bash
helm template platform-core . \
  --set bootstrap.gatekeeper.enabled=true \
  --set bootstrap.gatekeeper.policies.enabled=true
```

Test in dryrun mode before enforcing:
```bash
helm upgrade platform-core . \
  --set bootstrap.gatekeeper.policies.enforcementAction=dryrun
```

## Available Policy Categories

The Gatekeeper Library provides templates for:
- **Pod Security**: Privileged containers, root users, capabilities, host namespaces
- **Resource Management**: CPU/memory limits, required labels
- **Image Security**: Allowed registries, image signatures, latest tag
- **Network**: Host network/ports, ingress/egress restrictions
- **Volume Security**: hostPath restrictions, read-only root filesystem
- **RBAC**: Service account restrictions, role bindings

Full catalog: https://open-policy-agent.github.io/gatekeeper-library/website/docs/

## References

- [OPA Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/)
- [Gatekeeper Policy Library](https://open-policy-agent.github.io/gatekeeper-library/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
