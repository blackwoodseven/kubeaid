{{/*
Kubernetes standard labels
*/}}
{{- define "ox-common.labels.standard" -}}
app.kubernetes.io/name: {{ include "ox-common.names.name" . }}
helm.sh/chart: {{ include "ox-common.names.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: {{ .Chart.Name }}
version: {{ .Chart.AppVersion }}
{{- end -}}

{{/*
Labels to use on deploy.spec.selector.matchLabels and svc.spec.selector
*/}}
{{- define "ox-common.labels.matchLabels" -}}
app.kubernetes.io/name: {{ include "ox-common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Labels to use on deploy.spec.template.metadata
*/}}
{{- define "ox-common.labels.podLabels" -}}
app.kubernetes.io/name: {{ include "ox-common.names.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ .Chart.Name }}
version: {{ .Chart.AppVersion }}
{{- end -}}