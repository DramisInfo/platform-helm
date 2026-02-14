# Gatekeeper Policies

This directory contains OPA Gatekeeper policies that are deployed as part of the platform-core Helm chart.

## Structure

```
templates/gatekeeper-policies/
├── constraint-templates/       # ConstraintTemplate CRDs defining policy logic
│   ├── k8spspprivilegedcontainer.yaml
│   └── k8spspallowedusers.yaml
└── constraints/               # Constraint instances applying the policies
    ├── psp-privileged-container.yaml
    └── psp-must-run-as-nonroot.yaml
```

## Included Policies (CIS Benchmarks)

### 1. Block Privileged Containers (CIS 5.2.1)
**ConstraintTemplate**: `k8spspprivilegedcontainer`
**Constraint**: `psp-privileged-container`

Prevents containers from running in privileged mode, which gives them access to all devices and effectively disables container security.

### 2. Enforce Non-Root Users (CIS 5.2.6)
**ConstraintTemplate**: `k8spspallowedusers`
**Constraint**: `psp-pods-must-run-as-nonroot`

Requires all containers to run as non-root users to limit privilege escalation risks.

## Configuration

Policies are controlled via Helm values:

```yaml
bootstrap:
  gatekeeper:
    enabled: true      # Deploy Gatekeeper
    policies:
      enabled: true    # Deploy CIS policies
```

## Excluded Namespaces

System namespaces are excluded from policy enforcement:
- `kube-system`
- `gatekeeper-system`
- `cert-manager`
- `istio-system`
- `ingress-nginx`

## Adding New Policies

1. Add ConstraintTemplate to `constraint-templates/`
2. Create Constraint instance in `constraints/`
3. Wrap both files with Helm conditionals:
   ```yaml
   {{- if and .Values.bootstrap.gatekeeper.enabled .Values.bootstrap.gatekeeper.policies.enabled -}}
   # Your policy YAML here
   {{- end -}}
   ```

## Testing

Test a policy locally with Helm:
```bash
helm template platform-core . --set bootstrap.gatekeeper.enabled=true --set bootstrap.gatekeeper.policies.enabled=true
```

## Version Control

These policies are versioned with the platform-core Helm chart. When you deploy a specific chart version, you get the corresponding policy version, making testing and promotion easier.

## References

- [OPA Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/)
- [Gatekeeper Policy Library](https://open-policy-agent.github.io/gatekeeper-library/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
