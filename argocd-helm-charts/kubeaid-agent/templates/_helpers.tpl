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
  security-exporter runs as its own Deployment in this chart, with its
  own ServiceAccount and ClusterRole. It is deliberately not a sidecar: a pod
  carries one ServiceAccount, so co-locating the two would hand the workload
  holding the Obmondo mTLS credential the exporter's cluster-wide read across
  seven API groups — the exact coupling that splitting them removed.
*/}}
{{- define "kubeaid-agent.securityExporter.name" -}}
security-exporter
{{- end -}}

{{/*
  Fixed rather than release-derived. The agent's default
  appConfig.securityPosture.exporterURL is the literal string
  http://security-exporter, and a release-prefixed Service name would
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

{{/*
  backup-exporter runs as its own Deployment in this chart, with its own
  ServiceAccount and ClusterRole, for the same reason the security exporter
  does: a pod carries one ServiceAccount, so a sidecar would merge its cluster
  read into the workload holding the Obmondo credential.
*/}}

{{/*
  PINNED, and it must stay pinned. kubeaid-agent's Go code discovers this
  exporter by listing Deployments AND Services cluster-wide with the label
  selector app.kubernetes.io/name=backup-exporter
  (internal/core/backup/exporter.go). Deriving this from .Chart.Name would make
  it "kubeaid-agent" inside this chart, the selector would match nothing, and
  backups would silently stop being reported — discover() returns
  errExporterAbsent, which is indistinguishable from "not installed".
*/}}
{{- define "kubeaid-agent.backupExporter.name" -}}
backup-exporter
{{- end -}}

{{/*
  Also pinned. The upstream chart's fullname fell back to a bare .Release.Name,
  which inside this chart resolves to the agent's own release — so the exporter
  would try to create a Deployment and Service named kubeaid-agent and collide
  head-on with the agent's.
*/}}
{{- define "kubeaid-agent.backupExporter.fullname" -}}
{{- default (include "kubeaid-agent.backupExporter.name" .) .Values.backupExporter.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kubeaid-agent.backupExporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kubeaid-agent.backupExporter.labels" -}}
helm.sh/chart: {{ include "kubeaid-agent.backupExporter.chart" . }}
{{ include "kubeaid-agent.backupExporter.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: backup-exporter
{{- end }}

{{/*
  Carries the label the agent selects on. Applied to both the Deployment and
  the Service, because discover() lists both with the same selector.
*/}}
{{- define "kubeaid-agent.backupExporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubeaid-agent.backupExporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "kubeaid-agent.backupExporter.serviceAccountName" -}}
{{- if .Values.backupExporter.serviceAccount.create }}
{{- default (include "kubeaid-agent.backupExporter.fullname" .) .Values.backupExporter.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.backupExporter.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
  Convert duration strings (e.g. 24h, 60m, 60s) to seconds for Prometheus
  expressions.
*/}}
{{- define "kubeaid-agent.backupExporter.durationToSeconds" -}}
{{- $v := . | toString -}}
{{- if (hasSuffix "s" $v) -}}
  {{- trimSuffix "s" $v -}}
{{- else if (hasSuffix "m" $v) -}}
  {{- mul (trimSuffix "m" $v | int) 60 -}}
{{- else if (hasSuffix "h" $v) -}}
  {{- mul (trimSuffix "h" $v | int) 3600 -}}
{{- else if (hasSuffix "d" $v) -}}
  {{- mul (trimSuffix "d" $v | int) 86400 -}}
{{- else -}}
  {{- $v -}}
{{- end -}}
{{- end -}}
