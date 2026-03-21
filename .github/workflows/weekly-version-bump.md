---
name: Weekly Version Bump
description: |
  This workflow checks the versions of all Helm charts referenced in the ArgoCD applications that compose the platform-core helm chart, then opens a pull request to bump any that have newer releases.

on:
  schedule:
    - cron: "0 21 * * 5"  # Every Friday at 17:00 Eastern (UTC-4)
  workflow_dispatch:

permissions:
  contents: read
  issues: read
  pull-requests: read

network: defaults

tools:
  github:
    lockdown: false
    min-integrity: none
    repos: all
    github-app:
      app-id: ${{ secrets.APP_ID }}
      private-key: ${{ secrets.APP_PRIVATE_KEY }}

safe-outputs:
  mentions: false
  allowed-github-references: []
  create-pull-request:
    title-prefix: "[version-bump] "
    labels: [dependencies, automated]
    draft: true
    fallback-as-issue: false
    github-token-for-extra-empty-commit: app
engine: copilot
---

You are a version-tracking agent for this Helm chart repository. Your goal is to find every component that has a newer release available and open a pull request to bump those versions.

Start by exploring the repository to understand its structure. Look for ArgoCD application template files and any values files that contain pinned version strings — these are the sources of truth for what is currently deployed.

For each pinned version you find, figure out which upstream project it belongs to (using the chart name and repository URL as clues), then look up that project's latest stable release on GitHub. Ignore utility charts that do not publish versioned releases of their own. Ignore pre-releases and release candidates — only consider full stable releases.

Compare the current pinned version to the latest release. If the latest is newer, the component needs a bump. Update the version string in whichever file it lives in, making sure to update every occurrence for that component. Do not touch anything else in the files.

If you found at least one component to bump, open a draft pull request. The title should briefly list what changed. The body should contain:

1. A table showing each component alongside its old version, new version, and a link to the release page.

2. For each bumped component, a **"Release notes summary"** section. Fetch the GitHub release notes for every version between the old version (exclusive) and the new version (inclusive). Summarize the key changes — new features, deprecations, breaking changes, and notable bug fixes — in a concise bullet list. If multiple intermediate versions exist, group the highlights together rather than listing every release individually. Clearly call out any breaking changes or required migration steps.

3. A closing note reminding reviewers to consult the full release notes and changelogs before merging, especially for major or large minor version jumps.

If everything is already up to date, do nothing.

