{{/*
Expand the name of the chart.
*/}}
{{- define "obmondo-backup-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "obmondo-backup-exporter.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "obmondo-backup-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "obmondo-backup-exporter.labels" -}}
helm.sh/chart: {{ include "obmondo-backup-exporter.chart" . }}
{{ include "obmondo-backup-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "obmondo-backup-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "obmondo-backup-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "obmondo-backup-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "obmondo-backup-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Convert duration strings (e.g. 24h, 60m, 60s) to seconds for Prometheus expressions.
*/}}
{{- define "obmondo-backup-exporter.durationToSeconds" -}}
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
