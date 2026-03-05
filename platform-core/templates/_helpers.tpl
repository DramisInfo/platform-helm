{{/*
Default ArgoCD retry policy used by all Application templates.
Usage: {{- include "platform-core.defaultRetry" . | nindent 4 }}
*/}}
{{- define "platform-core.defaultRetry" -}}
retry:
  limit: 10
  backoff:
    duration: 5s
    factor: 2
    maxDuration: 30s
{{- end }}

{{/*
Extended ArgoCD retry policy for apps that depend on CRDs registered
asynchronously by Crossplane providers (e.g. crossplane-compositions).
Usage: {{- include "platform-core.extendedRetry" . | nindent 4 }}
*/}}
{{- define "platform-core.extendedRetry" -}}
retry:
  limit: 30
  backoff:
    duration: 10s
    factor: 2
    maxDuration: 3m
{{- end }}
