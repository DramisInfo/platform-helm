Grafana configuration in the Platform Core chart
===============================================

This chart exposes `bootstrap.grafana` values for the Grafana ArgoCD Application (via `argo-application.yaml`). You can use the following values to preinstall plugins and provision datasources from the top-level values file so that end-users do not need to install plugins via the Grafana UI.

Values supported
----------------

- `bootstrap.grafana.plugins` - An array of plugin IDs or plugin download URLs. Example: `grafana-github-datasource` or `https://grafana.com/api/plugins/grafana-github-datasource/versions/v2.3.0/download;grafana-github-datasource`
- `bootstrap.grafana.pluginsPreinstallSync` - Optional boolean to enable preinstall sync (chart version dependent). This sets the `GF_PLUGINS_PREINSTALL_SYNC` and `GF_PLUGINS_INSTALL` env variables on the Grafana release.
- `bootstrap.grafana.datasources` - An array of objects defining provisioned datasources (maps to `datasources.datasources.yaml` in the Grafana chart). Use this to create data sources on boot via provisioning.

Usage examples
--------------

Example: Preinstall GitHub plugin and provision a GitHub datasource (in your top-level values file that consumes this chart):

```yaml
bootstrap:
  grafana:
    enabled: true
    plugins:
      - grafana-github-datasource
    pluginsPreinstallSync: true
    datasources:
      - name: GitHub
        type: grafana-github-datasource
        access: proxy
        url: https://api.github.com
        jsonData:
          # plugin-specific config goes here
        secureJsonData:
          token: "__YOUR_TOKEN__"
```

Notes & Best Practices
----------------------
- Do not store API tokens in plain text in `values.yaml`. Use Kubernetes Secrets and reference them from your provisioning pipeline or mount secrets as needed.
- Plugin installation that is not preinstalled (via chart) must be performed by a Grafana server-admin user. The platform sets `auth.anonymous.org_role` to `Admin` for convenience; this does not give server-admin privileges required for plugin installation.
- Use the chart preinstall and provisioning features to avoid _UI-based_ plugin installs.

If you need help automating secret injection or sample provisioning for other plugins, I can add a an example `values-dev.yaml` and a short CI/CD snippet to inject secrets into the `datasources` or mount them to Grafana.
