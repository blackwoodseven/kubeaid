{{/*
These functions deal with cs global settings. Global settings are:

serviceName - the service name to be used by CacheService
enabled - determine if the cs service should use ssl connections or not

The input datastructure for is (with default values):

global:
  cs:
    serviceName: {{ .Release.Name }}-"core-cacheservice"
    ssl:
      enabled: false

The general usage to get the global CS service name is.

Example:

env:
    - name: CS_SERVICENAME
      value: {{ include "ox-common.cs.serviceName" . }}
    - name: CS_USE_SSL
      value: {{ include "ox-commons.cs.useSSL" . }}
    - name: CS_SERVER_URL
      value: {{ include "ox-common.cs.serverURL" . }}
*/}}

{{/*
Generates a CacheService name if none is given
*/}}
{{- define "ox-common.cs.generateCSServiceName" -}}
{{- printf "%s-%s" .Release.Name "core-cacheservice" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Provides CacheService name
*/}}
{{- define "ox-common.cs.serviceName" -}}
{{- $serviceName := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.cs }}
    {{- $serviceName = .Values.global.cs.serviceName -}}
  {{- end -}}
{{- end -}}
{{- $serviceName | default (include "ox-common.cs.generateCSServiceName" . ) -}}
{{- end -}}

{{/*
Provides the ssl config state of the CacheService
*/}}
{{- define "ox-common.cs.ssl.enabled" -}}
{{- $javaSSLEnabled := (include "ox-common.java.ssl.enabled" .) -}}
{{- $csSSLEnabled := $javaSSLEnabled -}}
{{- if eq $javaSSLEnabled "true" -}}
  {{- if .Values -}}
    {{- if .Values.global -}}
      {{- if .Values.global.cs -}}
        {{- if .Values.global.cs.ssl -}}
          {{- $csSSLEnabled = .Values.global.cs.ssl.enabled | default false -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $csSSLEnabled -}}
{{- end -}}

{{/*
Provides the CS server URL depending on enabled SSL and appropriate ports and protocols
*/}}
{{- define "ox-common.cs.serverURL" -}}
{{- if eq (include "ox-common.cs.ssl.enabled" .) "true" -}}
  {{- (printf "https://%s.%s:8001/cache" (include "ox-common.cs.serviceName" .) .Release.Namespace)  | trimSuffix "-"  -}}
{{- else -}}
  {{- (printf "http://%s.%s:8001/cache" (include "ox-common.cs.serviceName" .) .Release.Namespace) | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
