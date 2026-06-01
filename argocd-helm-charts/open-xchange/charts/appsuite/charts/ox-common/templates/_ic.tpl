{{/*
These functions deal with ic global settings. Global settings are:

serviceName - the service name to be used by ImageConverter service
enabled - determine if the ic service should use ssl connections or not

The input datastructure for is (with default values):

global:
  ic:
    serviceName: {{ .Release.Name }}-"core-imageconverter"
    ssl:
      enabled: false

The general usage to get the global IC service name is.

Example:

env:
    - name: IC_SERVICENAME
      value: {{ include "ox-common.ic.serviceName" . }}
    - name: IC_USE_SSL
      value: {{ include "ox-commons.ic.useSSL" . }}
    - name: IC_SERVER_URL
      value: {{ include "ox-common.ic.serverURL" . }}
*/}}

{{/*
Generates a ImageConverter service name if none is given
*/}}
{{- define "ox-common.ic.generateICServiceName" -}}
{{- printf "%s-%s" .Release.Name "core-imageconverter" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Provides ImageConverter service name
*/}}
{{- define "ox-common.ic.serviceName" -}}
{{- $serviceName := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.ic }}
    {{- $serviceName = .Values.global.ic.serviceName -}}
  {{- end -}}
{{- end -}}
{{- $serviceName | default (include "ox-common.ic.generateICServiceName" . ) -}}
{{- end -}}

{{/*
Provides the ssl config state of the ImageConverter service
*/}}
{{- define "ox-common.ic.ssl.enabled" -}}
{{- $javaSSLEnabled := (include "ox-common.java.ssl.enabled" .) -}}
{{- $icSSLEnabled := $javaSSLEnabled -}}
{{- if eq $javaSSLEnabled "true" -}}
  {{- if .Values -}}
    {{- if .Values.global -}}
      {{- if .Values.global.ic -}}
        {{- if .Values.global.ic.ssl -}}
          {{- $icSSLEnabled = .Values.global.ic.ssl.enabled | default false -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $icSSLEnabled -}}
{{- end -}}

{{/*
Provides the IC server URL depending on enabled SSL and appropriate ports and protocols
*/}}
{{- define "ox-common.ic.serverURL" -}}
{{- if eq (include "ox-common.ic.ssl.enabled" .) "true" -}}
  {{- (printf "https://%s.%s:8014/imageconverter" (include "ox-common.ic.serviceName" .) .Release.Namespace)  | trimSuffix "-"  -}}
{{- else -}}
  {{- (printf "http://%s.%s:8005/imageconverter" (include "ox-common.ic.serviceName" .) .Release.Namespace) | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
