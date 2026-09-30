{{/* Chart name. */}}
{{- define "linuxaid-security-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Resource name: the chart name, as the agent's other exporters use, or fullnameOverride. */}}
{{- define "linuxaid-security-exporter.fullname" -}}
{{- default (include "linuxaid-security-exporter.name" .) .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels. */}}
{{- define "linuxaid-security-exporter.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "linuxaid-security-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}

{{/* Selector labels. */}}
{{- define "linuxaid-security-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "linuxaid-security-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Volume name for a host path: the path with its slashes turned into dashes, so
"/" becomes host-root and "/var/lib/dpkg" becomes host-var-lib-dpkg.
*/}}
{{- define "linuxaid-security-exporter.hostVolumeName" -}}
{{- printf "host-%s" (. | replace "/" "-" | trimAll "-" | default "root") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Where a host path is mounted inside the pod: /host, then the path itself. */}}
{{- define "linuxaid-security-exporter.hostMountPath" -}}
{{- printf "/host%s" (trimSuffix "/" .) -}}
{{- end -}}
