{{/*
Additional helpers to reduce repetition in NetworkPolicies
*/}}

{{/* Kube-DNS pod selector labels */}}
{{- define "ciso-assistant.kubeDnsSelectorLabels" -}}
io.kubernetes.pod.namespace: kube-system
k8s-app: kube-dns
{{- end }}

{{/* CloudNativePG cluster pod selector labels */}}
{{- define "ciso-assistant.pgClusterSelectorLabels" -}}
io.kubernetes.pod.namespace: {{ .Release.Namespace }}
cnpg.io/cluster: {{ if (.Values.postgres).recover }}ciso-assistant-pgsql-recover{{ else }}ciso-assistant-pgsql{{ end }}
{{- end }}

{{/* PostgreSQL port as string (from values) */}}
{{- define "ciso-assistant.pgSqlPort" -}}
{{- $ca := index .Values "ciso-assistant-next" -}}
{{- toString $ca.externalPgsql.port -}}
{{- end }}
