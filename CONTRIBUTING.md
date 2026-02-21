# Contributing to platform-helm

Thank you for your interest in contributing! We welcome bug reports, feature requests, and pull requests.

## Getting Started

1. **Fork** the repository and clone your fork locally.
2. Create a new branch from `main`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. Make your changes and verify them locally (see [Development](#development) below).
4. Push your branch and open a Pull Request against `main`.

## Development

### Prerequisites

- Helm v3
- A Kubernetes cluster (local or remote) with Argo CD installed

### Validate your changes

```bash
# Lint the chart
helm lint platform-core

# Render templates to stdout (dry-run)
helm template platform-core ./platform-core
```

The CI pipeline runs these checks automatically on every PR.

## Pull Request Guidelines

- Keep PRs focused — one feature or fix per PR.
- Provide a clear description of what changed and why.
- Update `values.yaml` comments if you change or add configuration options.
- Bump the chart `version` in `platform-core/Chart.yaml` following [Semantic Versioning](https://semver.org/):
  - **Patch** (`0.0.x`) — bug fixes and minor tweaks
  - **Minor** (`0.x.0`) — new features, backwards-compatible
  - **Major** (`x.0.0`) — breaking changes

## Reporting Issues

Please use [GitHub Issues](../../issues) to report bugs or request features. Include as much context as possible:

- Kubernetes version
- Helm version
- Argo CD version
- Relevant `values.yaml` snippet
- Error messages or unexpected behaviour

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold its standards.
