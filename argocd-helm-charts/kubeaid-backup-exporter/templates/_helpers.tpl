{{/* Chart name, or nameOverride. */}}
{{- define "backup-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "backup-exporter.fullname" -}}
{{- default (include "backup-exporter.name" .) .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "backup-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "backup-exporter.labels" -}}
helm.sh/chart: {{ include "backup-exporter.chart" . }}
{{ include "backup-exporter.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: backup-exporter
{{- end }}

{{/*
  Pod selector for the Deployment and the Service. kubeaid-agent and kubeaid-cli
  find the exporter by the fixed app.kubernetes.io/component label instead.
*/}}
{{- define "backup-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "backup-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "backup-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "backup-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
  Convert duration strings (e.g. 24h, 60m, 60s) to seconds for Prometheus
  expressions.
*/}}
{{- define "backup-exporter.durationToSeconds" -}}
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

{{/*
  Seconds between the exporter's collection passes, derived as backup-exporter's
  ParseExporterSchedule does: max_rpo × interval_rate (a rate outside (0, 1]
  means 0.25), floored to whole hours and capped at a day, or to whole minutes
  below an hour. Takes (list max_rpo interval_rate).
*/}}
{{- define "backup-exporter.passSeconds" -}}
{{- $rpo := include "backup-exporter.durationToSeconds" (index . 0) | float64 -}}
{{- $rate := index . 1 | default 0.25 | float64 -}}
{{- if or (le $rate 0.0) (gt $rate 1.0) -}}
  {{- $rate = 0.25 -}}
{{- end -}}
{{- $pass := mulf $rpo $rate | int -}}
{{- if ge $pass 86400 -}}
  {{- 86400 -}}
{{- else if ge $pass 3600 -}}
  {{- mul (div $pass 3600) 3600 -}}
{{- else -}}
  {{- max 60 (mul (div $pass 60) 60) -}}
{{- end -}}
{{- end -}}
