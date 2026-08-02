# Related repos

This repo is part of the DramisInfo home-lab platform stack. The
other repos in the stack:

- [DramisInfo/home-lab](https://github.com/DramisInfo/home-lab) —
  Source of truth for cluster topology, hardware, network layout,
  and high-level architecture decisions.
- [DramisInfo/platform-tools](https://github.com/DramisInfo/platform-tools) —
  Shared scripts, CLIs, and helper tooling used across the stack.
- [DramisInfo/platform-helm](https://github.com/DramisInfo/platform-helm) —
  The platform-core Helm chart (umbrella chart that composes all
  platform services).
- [DramisInfo/platform-crossplane-compositions](https://github.com/DramisInfo/platform-crossplane-compositions) —
  Crossplane CompositeResourceDefinitions and Compositions that
  project Azure resources into the cluster via Azure Arc.
- [DramisInfo/platform-project-workspaces](https://github.com/DramisInfo/platform-project-workspaces) —
  Per-project tenant workspaces: namespaces, RBAC, quotas, and
  Argo CD ApplicationSets scoped to a single project.
- [DramisInfo/platform-standards](https://github.com/DramisInfo/platform-standards) —
  Repo-wide conventions, schemas, and policy documents referenced
  by all other repos.
- [DramisInfo/platform-workflows](https://github.com/DramisInfo/platform-workflows) —
  Reusable GitHub Actions workflows and composite actions.
- [DramisInfo/crossplane-providers-and-functions](https://github.com/DramisInfo/crossplane-providers-and-functions) —
  Custom Crossplane providers and composition functions used by
  the platform-crossplane-compositions stack.
