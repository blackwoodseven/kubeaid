{{- define "coturn.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "coturn.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "labels" -}}
helm.sh/chart: {{ include "coturn.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: "coturn"
{{- end -}}


{{/*
Create image name that is used in the deployment
*/}}
{{- define "coturn.image" -}}
{{- if .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository .Chart.AppVersion -}}
{{- end -}}
{{- end -}}

{{/*
Helper function to get the coturn secret containing db credentials
*/}}
{{- define "database.secretName" -}}
{{- if .Values.externalDatabase.existingSecret -}}
{{ .Values.externalDatabase.existingSecret }}
{{- else if and .Values.cnpg.enabled .Values.cnpg.cluster.initdb.secret.name -}}
{{ .Values.cnpg.cluster.initdb.secret.name }}
{{- else if .Values.mysql.enabled -}}
{{- with (first .Values.mysql.users) -}}
{{ .passwordSecretRef.name }}
{{- end }}
{{- else -}}
{{ .Release.Name }}-db-secret
{{- end -}}
{{- end -}}

{{/*
Helper function to get the coturn secret containing admin coturn credentials
*/}}
{{- define "coturn.auth.secretName" -}}
{{- if .Values.coturn.auth.existingSecret -}}
{{ .Values.coturn.auth.existingSecret }}
{{- else -}}
{{ .Release.Name }}-auth-secret
{{- end }}
{{- end }}

{{- define "db.envVars" -}}
{{- if .Values.externalDatabase.enabled -}}
- name: DATABASE_HOSTNAME
  valueFrom:
    secretKeyRef:
      name: {{ include "database.secretName" . }}
      {{- if and .Values.externalDatabase.enabled .Values.externalDatabase.secretKeys.hostname }}
      key: {{ .Values.externalDatabase.secretKeys.hostname }}
      {{- else }}
      key: hostname
      {{- end }}

- name: DATABASE_USER
  {{- if and .Values.externalDatabase.enabled .Values.externalDatabase.secretKeys.username }}
  valueFrom:
    secretKeyRef:
      name: {{ include "database.secretName" . }}
      key: {{ .Values.externalDatabase.secretKeys.username }}
  {{- else if .Values.cnpg.enabled }}
  value: {{ .Values.cnpg.cluster.initdb.owner }}
  {{- else if .Values.mysql.enabled }}
  {{- with (first .Values.mysql.users) }}
  value: {{ .name | b64enc | quote }}
  {{- end }}
  {{- end }}

- name: DATABASE_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "database.secretName" . }}
      {{- if and .Values.externalDatabase.enabled .Values.externalDatabase.secretKeys.password }}
      key: {{ .Values.externalDatabase.secretKeys.password }}
      {{- else }}
      key: password
      {{- end }}

- name: DATABASE
  valueFrom:
    secretKeyRef:
      name: {{ include "database.secretName" . }}
      {{- if and .Values.externalDatabase.enabled .Values.externalDatabase.secretKeys.database }}
      key: {{ .Values.externalDatabase.secretKeys.database }}
      {{- else }}
      key: database
      {{- end }}
{{- end }}
{{- end }}
