{{/*
  Name and fullname default to the chart name rather than being release-prefixed.
  There is one of these per cluster, and kubeaid-agent's default
  appConfig.securityPosture.exporterURL is the literal string
  http://kubeaid-security-exporter -- a release-prefixed Service would leave the agent
  polling a host that does not resolve, which fails QUIETLY, because a failed
  poll only sets a metric and submits nothing.
*/}}
{{- define "kubeaid-security-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kubeaid-security-exporter.fullname" -}}
{{- default (include "kubeaid-security-exporter.name" .) .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kubeaid-security-exporter.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "kubeaid-security-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: kubeaid-security-exporter
{{- end -}}

{{/*
  Distinct from the agent's selector labels on purpose: the Deployments in this
  release must not select each other's pods.
*/}}
{{- define "kubeaid-security-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubeaid-security-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
