{{/* Determine the final chart name. */}}
{{- define "kubeaid-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Determine the final application name. */}}
{{- define "kubeaid-agent.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Common conventional labels. */}}
{{- define "kubeaid-agent.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "kubeaid-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}

{{/* Selector labels. */}}
{{- define "kubeaid-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubeaid-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
  kubeaid-security-exporter runs as a SECOND Deployment in this chart, with its
  own ServiceAccount and ClusterRole. It is deliberately not a sidecar: a pod
  carries one ServiceAccount, so co-locating the two would hand the workload
  holding the Obmondo mTLS credential the exporter's cluster-wide read across
  seven API groups — the exact coupling that splitting them removed.
*/}}
{{- define "kubeaid-agent.securityExporter.name" -}}
kubeaid-security-exporter
{{- end -}}

{{/*
  Fixed rather than release-derived. The agent's default
  appConfig.securityPosture.exporterURL is the literal string
  http://kubeaid-security-exporter, and a release-prefixed Service name would
  leave the agent polling a host that does not resolve — which fails QUIETLY,
  because a failed poll only sets a metric and submits nothing.
*/}}
{{- define "kubeaid-agent.securityExporter.fullname" -}}
{{- default (include "kubeaid-agent.securityExporter.name" .) .Values.securityExporter.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kubeaid-agent.securityExporter.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "kubeaid-agent.securityExporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: security-exporter
{{- end -}}

{{/*
  Distinct from the agent's selector labels on purpose: two Deployments in one
  release must not select each other's pods.
*/}}
{{- define "kubeaid-agent.securityExporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubeaid-agent.securityExporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
