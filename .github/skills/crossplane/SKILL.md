---
name: crossplane
description: This skill provides guidance for creating managed resources in Crossplane, a Kubernetes add-on that enables platform teams to provision and manage cloud infrastructure using Kubernetes APIs. It includes instructions on how to define and deploy Crossplane managed resources, as well as examples of common use cases.

---

# Crossplane Skill

## Overview

Crossplane is a Kubernetes add-on that extends the cluster with the ability to provision and manage cloud infrastructure using Kubernetes-native APIs. In this repository, Crossplane is deployed as an Argo CD `Application` via the meta-chart pattern (see `platform-core/templates/argo-applications/crossplane/crossplane.yaml`).

Crossplane's core object model has four layers:

| Layer | Object | Purpose |
|---|---|---|
| 1 | **Provider** | Installs a controller + CRDs for a cloud (AWS, Azure, GCP, etc.) |
| 2 | **ProviderConfig** | Holds credentials/configuration used by the Provider |
| 3 | **Managed Resource (MR)** | A single external resource (e.g. S3 Bucket, RDS Instance) |
| 4 | **Composition / XRD / XR** | Abstracts one or more MRs behind a custom API |

---

## Adding a Crossplane Provider

Providers are installed as their own Argo CD `Application` templates.

**Steps:**

1. Create `platform-core/templates/argo-applications/crossplane/<provider-name>.yaml`
2. Wrap in `{{- if .Values.bootstrap.crossplane.<provider>.enabled -}} ... {{- end -}}`
3. Use sync-wave `-25` (after Crossplane at `-30`, before workloads that depend on it)
4. Pin `targetRevision` to an exact package version

**Example — AWS S3 Provider:**

```yaml
{{- if .Values.bootstrap.crossplane.providerAwsS3.enabled -}}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crossplane-provider-aws-s3
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-25"
spec:
  destination:
    namespace: crossplane-system
    server: "https://kubernetes.default.svc"
  project: default
  source:
    repoURL: "https://charts.crossplane.io/stable"
    chart: crossplane
    targetRevision: "2.2.0"
    helm:
      valuesObject:
        provider:
          packages:
            - xpkg.crossplane.io/crossplane-contrib/provider-aws-s3:v2.0.0
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - Wait=true
{{- end -}}
```

Add the toggle to `values.yaml`:
```yaml
bootstrap:
  crossplane:
    enabled: false
    providerAwsS3:
      # enabled -- Install the AWS S3 Crossplane provider
      enabled: false
```

---

## ProviderConfig (Credentials)

A `ProviderConfig` tells the provider how to authenticate with the cloud. It is deployed as a plain Kubernetes manifest (not via Helm), typically sourced from a Secret created by the External Secrets Operator.

```yaml
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-credentials
      key: credentials
```

All security contexts on provider pods must comply with Gatekeeper policies:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]`
- `seccompProfile.type: RuntimeDefault`

---

## Managed Resources (MRs)

A Managed Resource maps directly to one external API resource. Use `spec.forProvider` to configure it and `spec.providerConfigRef` to select credentials.

```yaml
apiVersion: s3.aws.m.upbound.io/v1beta1
kind: Bucket
metadata:
  name: my-bucket
spec:
  forProvider:
    region: us-east-1
  providerConfigRef:
    name: default   # references the ProviderConfig above
```

### Managed Resource Readiness Conditions

| Condition | Reason | Meaning |
|---|---|---|
| `Ready: False` | `Creating` | Provider is provisioning the resource |
| `Ready: True` | `Available` | Resource is live and usable |
| `Synced: False` | `ReconcileError` | Provider hit an error, check `kubectl describe` |

```bash
kubectl get managed               # all managed resources across providers
kubectl describe <kind> <name>    # full status + events
```

---

## Composite Resources (XRD + Composition)

Use Compositions to expose a higher-level API that provisions multiple Managed Resources atomically.

### 1 — Define the API Schema (XRD)

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xdatabases.example.org
spec:
  scope: Namespaced          # Namespaced (v2 default) or Cluster
  group: example.org
  names:
    kind: XDatabase
    plural: xdatabases
  versions:
  - name: v1alpha1
    served: true
    referenceable: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              region:
                type: string
                description: Cloud region where the database is provisioned.
            required:
              - region
```

```bash
kubectl apply -f xrd.yaml
kubectl get xrd                   # ESTABLISHED=True when ready
```

### 2 — Define the Composition (Pipeline mode)

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: xdatabase-aws
spec:
  compositeTypeRef:
    apiVersion: example.org/v1alpha1
    kind: XDatabase
  mode: Pipeline
  pipeline:
  - step: patch-and-transform
    functionRef:
      name: function-patch-and-transform
    input:
      apiVersion: pt.fn.crossplane.io/v1beta1
      kind: Resources
      resources:
      - name: rds-instance
        base:
          apiVersion: rds.aws.m.upbound.io/v1beta1
          kind: Instance
          spec:
            forProvider:
              region: us-east-1     # overridden by patch below
        patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.region
          toFieldPath: spec.forProvider.region
```

### 3 — Claim a Composite Resource

```yaml
apiVersion: example.org/v1alpha1
kind: XDatabase
metadata:
  name: my-db
  namespace: default
spec:
  region: eu-west-1
```

### Composition Policies

| XRD field | Effect |
|---|---|
| `defaultCompositionRef.name` | Used when no explicit Composition is referenced |
| `enforcedCompositionRef.name` | Forces all XRs to use this Composition; cannot be overridden |
| `defaultCompositionUpdatePolicy: Manual` | Stops auto-update when a new Composition revision is published |

---

## Dry-Run and Validation

```bash
# Lint the chart
helm lint platform-core

# Render all templates
helm template platform-core ./platform-core

# Render with custom values
helm template platform-core ./platform-core -f my-values.yaml

# Verify XRDs in the cluster
kubectl get xrd
kubectl api-resources | grep example.org

# Dry-run render a Composition locally (requires crossplane CLI)
crossplane render xr.yaml composition.yaml functions.yaml
```

---

## Key References

| Resource | Source |
|---|---|
| Crossplane docs | https://docs.crossplane.io/latest/ |
| Crossplane Helm chart | https://charts.crossplane.io/stable |
| Upbound provider registry | https://marketplace.upbound.io/providers |
| Composition patch-and-transform | https://docs.crossplane.io/latest/guides/function-patch-and-transform |
| Composite Resource Definitions | https://docs.crossplane.io/latest/composition/composite-resource-definitions |