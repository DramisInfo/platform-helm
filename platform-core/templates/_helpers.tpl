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
