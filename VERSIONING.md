# Automatic Semantic Versioning

This repository uses automatic semantic versioning based on conventional commit messages.

## How it works

1. **CI Pipeline**: When code is pushed to `main`, the CI pipeline runs tests
2. **Automatic Versioning**: After tests pass, the version is automatically bumped based on commit messages
3. **Version Commit**: The new version is committed with `[skip ci]` to prevent infinite loops
4. **Git Tag**: A corresponding git tag is created and pushed

## Version Bump Rules

The version bump type is determined by analyzing the commit message:

### Major Version Bump (x.0.0)
- Breaking changes indicated by:
  - `feat!:` or `feature!:` 
  - `BREAKING CHANGE:` in commit message
  - `breaking change` anywhere in commit message

### Minor Version Bump (x.y.0)
- New features indicated by:
  - `feat:` or `feature:`
  - `feat(scope):` or `feature(scope):`

### Patch Version Bump (x.y.z)
- Everything else (bug fixes, chores, docs, etc.)

## Examples

```bash
# Patch bump (0.6.0 → 0.6.1)
git commit -m "fix: resolve authentication issue"
git commit -m "chore: update dependencies"
git commit -m "docs: improve README"

# Minor bump (0.6.0 → 0.7.0)
git commit -m "feat: add new user dashboard"
git commit -m "feature(auth): implement OAuth2 support"

# Major bump (0.6.0 → 1.0.0)
git commit -m "feat!: redesign API with breaking changes"
git commit -m "feature: new auth system

BREAKING CHANGE: This changes the authentication flow"
```

## Current Workflow

1. Developer pushes changes to `main`
2. CI runs tests and linting
3. If tests pass, version is automatically bumped in `Chart.yaml`
4. New version is committed with `[skip ci]` message
5. Git tag is created (e.g., `v0.6.1`)
6. Platform-tools repository is updated with the new version

## Preventing Infinite Loops

The system prevents infinite loops by:
- Using `[skip ci]` in version bump commit messages
- Checking commit messages to skip CI when `[skip ci]` or `[ci skip]` is present
