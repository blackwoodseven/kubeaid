{{/*
  app.kubernetes.io/name MUST stay "backup-exporter". kubeaid-agent discovers
  this exporter by listing Deployments AND Services with the selector
  app.kubernetes.io/name=backup-exporter (internal/core/backup/exporter.go), and
  kubeaid-cli does the same. Rename it and discover() returns errExporterAbsent,
  which is indistinguishable from "not installed" -- backups simply stop being
  reported, with nothing failing.

  The chart is named kubeaid-backup-exporter, so the .Chart.Name default would
  now give the wrong answer: values.yaml pins nameOverride to backup-exporter,
  and it must stay pinned.
*/}}
{{- define "backup-exporter.name" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if ne $name "backup-exporter" -}}
{{- fail "kubeaid-backup-exporter: nameOverride must stay \"backup-exporter\" — kubeaid-agent and kubeaid-cli find this exporter by app.kubernetes.io/name, and a different value makes them report it as not installed. The pin goes once every cluster runs versions that select on app.kubernetes.io/component." -}}
{{- end -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
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
  Carries the label the agent selects on. Applied to both the Deployment and the
  Service, because discover() lists both with the same selector.
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
