{{/*
Expand the name of the chart.
*/}}
{{- define "core-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "core-ui.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "core-ui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "core-ui.labels" -}}
helm.sh/chart: {{ include "core-ui.chart" . }}
{{ include "core-ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "core-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "core-ui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "core-ui.jwksSecret" -}}
{{ default "core-ui-jwks-secret" .Values.jwks.existingSecret }}
{{- end -}}

{{- define "core-ui.env" -}}
- name: BIND_ADDR
  value: {{ .Values.bindAddr | default "::" | quote }}
- name: PORT
  value: {{ .Values.containerPort | default 8080 | quote }}
- name: METRICS_PORT
  value: {{ .Values.metricsPost | default 9090 | quote }}
- name: LOG_LEVEL
  value: {{ .Values.logLevel | quote }}
- name: ORIGINS
  value: {{ .Values.origins | quote }}
- name: EXPOSE_API_DOCS
  value: {{ .Values.exposeApiDocs | quote }}
- name: CONFIG_PATH
  value: "/app/config"
- name: JWKS_CERT_PATH
  value: "/app/jwks-cert"
- name: JWKS_ENABLED
  value: {{ .Values.jwks.enabled | quote }}
{{- if .Values.jwks.enabled }}
- name: JWKS_ISSUER
  value: {{ .Values.jwks.issuer | default .Values.istio.hostname | quote }}
- name: JWT_CAPABILITIES
  value: {{ .Values.jwt.capabilities | quote }}
- name: JWT_ALGORITHM
  value: {{ .Values.jwt.algorithm | quote }}
- name: JWT_EXPIRATION
  value: {{ .Values.jwt.expiration | quote }}
- name: APP_ROOT
  value: {{ include "ox-common.appsuite.appRoot" . | default "" | quote }}
- name: APP_SUITE_API
  value: {{ .Values.appsuite.api | default .Values.istio.hostname | quote }}
- name: APP_SUITE_APP_ID
  value: {{ .Values.appsuite.appId | quote }}
{{- end -}}
{{- if and .Values.databases (gt (len .Values.databases) 0) }}
- name: DATABASES
  valueFrom:
    secretKeyRef:
      name: {{ .Values.overrides.dbSecret | quote }}
      key: DATABASES
- name: DB_BIMI_HOST
  valueFrom:
    secretKeyRef:
      name: {{ .Values.overrides.dbSecret | quote }}
      key: DB_BIMI_HOST
- name: DB_BIMI_PORT
  valueFrom:
    secretKeyRef:
      name: {{ .Values.overrides.dbSecret | quote }}
      key: DB_BIMI_PORT
- name: DB_BIMI_NAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.overrides.dbSecret | quote }}
      key: DB_BIMI_NAME
- name: DB_BIMI_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.overrides.dbSecret | quote }}
      key: DB_BIMI_USER
- name: DB_BIMI_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.overrides.dbSecret | quote }}
      key: DB_BIMI_PASSWORD
{{- end -}}
{{- end -}}

{{- define "core-ui.volumes" -}}
- name: config
  configMap:
    name: {{ include "ox-common.names.fullname" . }}-config
{{- if .Values.jwks.enabled }}
- name: jwks-cert
  secret:
    secretName: {{ include "core-ui.jwksSecret" . }}
{{- end }}
{{- end -}}

{{- define "core-ui.volumeMounts" -}}
- name: config
  mountPath: /app/config
  readOnly: true
{{- if .Values.jwks.enabled }}
- name: jwks-cert
  mountPath: /app/jwks-cert
  readOnly: true
{{- end }}
{{- end -}}

{{/*
Return non-empty when databases are configured.
*/}}
{{- define "core-ui.hasDatabases" -}}
{{- if and .Values.databases (gt (len .Values.databases) 0) }}true{{ end }}
{{- end -}}
