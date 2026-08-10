# platform-helm docs

This folder holds the user guide and architecture documentation for the
`platform-helm` repo. It complements (does not replace) the top-level
[`README.md`](../README.md).

## Contents

- [`overview.md`](overview.md) — what this repo is, who uses it, when to
  touch it, and where it fits in the DramisInfo platform stack.
- [`architecture.md`](architecture.md) — how the chart, Argo CD
  AppProjects, sync waves, and downstream components fit together.
- [`user-guide.md`](user-guide.md) — day-to-day tasks: lint, render,
  install, override values for a cluster, common operations, and
  troubleshooting.
- [`related-repos.md`](related-repos.md) — pointer list to sibling
  DramisInfo repos in the home-lab platform stack.

## How to navigate

If you are new to the repo, start with `overview.md`, then read
`architecture.md` to understand how `platform-core` delegates work to
Argo CD. Use `user-guide.md` as a reference when running chart commands
or editing cluster overrides. Use `related-repos.md` to find which
neighboring repo owns a given concern (cluster bootstrap, Crossplane
compositions, project workspaces, shared standards, CI workflows).

## Scope of these docs

These documents describe the `platform-core` Helm chart as it exists in
this repository. They do not cover day-0 cluster bootstrap, Crossplane
composition authoring, or workspace provisioning — those live in their
own repos and are listed in `related-repos.md`.
