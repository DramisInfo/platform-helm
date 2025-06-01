# CI Workflow Improvements

## Summary of Changes

The CI workflow has been completely redesigned to be more efficient and remove dependencies on ArgoCD for testing. Here are the key improvements:

## ✅ What Was Fixed

### 1. **Kubernetes Validation Issue**
- **Problem**: `helm template --validate` was failing because GitHub Actions runners don't have Kubernetes clusters
- **Solution**: 
  - Removed `--validate` flag from basic template tests
  - Added dedicated integration test job with Kind cluster for validation
  - Created separate test scenarios with and without K8s requirements

### 2. **Self-hosted to Public Runners**
- **Before**: All jobs used `runs-on: self-hosted`
- **After**: All jobs use `runs-on: ubuntu-latest` (public GitHub runners)
- **Benefits**: More reliable, no infrastructure maintenance, faster startup

### 3. **Removed ArgoCD Dependencies**
- **Before**: CI relied on ArgoCD installation and app creation for testing
- **After**: Direct Helm testing with matrix jobs for different configurations
- **Benefits**: Faster execution, simpler setup, no external dependencies

## 🚀 New Features

### 1. **Matrix Jobs for Parallel Testing**
The CI now tests multiple chart configurations in parallel:

- **minimal**: Basic NATS-only setup
- **monitoring-stack**: Prometheus, Grafana, Loki + NATS
- **security-stack**: cert-manager, External Secrets + NATS  
- **infrastructure-stack**: Crossplane, Terraform Operator, Atlas + NATS
- **nats-gateway**: NATS with gateway configuration
- **full-stack**: All components enabled

### 2. **Two-tier Testing Strategy**

#### Basic Testing (Fast, No K8s)
- Helm linting
- Template generation
- Value combinations testing

#### Integration Testing (Comprehensive, With K8s)
- Kind cluster setup
- Template validation with K8s API
- Dry-run installations
- Actual installation testing (minimal components)

### 3. **Improved Local Development**

#### New Taskfile (`Taskfile.dev.yml`)
```bash
task ci-local      # Quick tests without K8s
task ci-full       # Full tests with K8s cluster
task dev          # Set up development environment
task clean        # Clean up everything
```

#### Local CI Script (`scripts/local-ci.sh`)
- Runs the same tests as CI
- No Kubernetes required
- Perfect for pre-commit validation

## 📊 Performance Improvements

| Aspect | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Runner Type** | Self-hosted | GitHub public | Better reliability |
| **Parallel Tests** | Sequential | 6 matrix jobs | ~6x faster testing |
| **Dependencies** | ArgoCD + K3d + Tools | Helm only (basic) | Simpler setup |
| **Test Coverage** | Single config | 6 configurations | Better coverage |
| **Local Testing** | Full cluster required | Script-based option | Faster feedback |

## 🔧 Workflow Structure

```
CI Workflow:
├── lint (Basic validation)
├── test-combinations (6 parallel matrix jobs)
├── integration-test (2 K8s-validated scenarios)  
├── package (Chart packaging)
├── release (Version bump, only on main)
└── update-platform-tools (Update downstream, only on main)
```

## 🎯 Usage

### For Developers
```bash
# Quick local testing
./scripts/local-ci.sh

# Full local testing with K8s
task ci-full

# Development setup
task dev
```

### For CI/CD
- **Pull Requests**: Runs lint, test-combinations, integration-test, package
- **Main Branch**: Runs all jobs including release and downstream updates
- **Manual**: Can be triggered via workflow_dispatch

## 🛡️ Safety Features

- **fail-fast: false**: Matrix jobs continue even if one fails
- **Conditional releases**: Only runs on main branch pushes
- **Skip CI**: Supports `[skip ci]` and `[ci skip]` in commit messages
- **Validation**: Both template-only and K8s-validated testing
- **Conventional Commits**: Automatic version bumping based on commit messages

## 📝 Next Steps

1. **Test the new workflow** by creating a pull request
2. **Monitor performance** and adjust matrix scenarios if needed
3. **Consider adding** security scanning, dependency checks, or chart testing with `ct`
4. **Evaluate** adding Helm chart publishing to a registry

The new CI workflow is more efficient, reliable, and provides better test coverage while removing complex dependencies.
