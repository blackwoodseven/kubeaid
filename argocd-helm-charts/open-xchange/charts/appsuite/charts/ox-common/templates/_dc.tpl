{{/*
These functions deal with dc global settings. Global settings are:

serviceName - the service name to be used by DocumentConverter service
enabled - determine if the dc service should use ssl connections or not

The input datastructure for is (with default values):

global:
  dc:
    serviceName: {{ .Release.Name }}-"core-documentconverter"
    ssl:
      enabled: false

The general usage to get the global DC service name is.

Example:

env:
    - name: DC_SERVICENAME
      value: {{ include "ox-common.dc.serviceName" . }}
    - name: DC_USE_SSL
      value: {{ include "ox-common.dc.ssl.enabled" . }}
    - name: DC_SERVER_URL
      value: {{ include "ox-common.dc.serverURL" . }}
*/}}

{{/*
Provides DocumentConverter service name
*/}}
{{- define "ox-common.dc.serviceName" -}}
{{- $serviceName := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.dc }}
    {{- $serviceName = .Values.global.dc.serviceName -}}
  {{- end -}}
{{- end -}}
{{- $serviceName | default (printf "%s-%s" .Release.Name "core-documentconverter" | trunc 63 | trimSuffix "-") -}}
{{- end -}}

{{/*
Provides the ssl config state of the DocumentConverter service
*/}}
{{- define "ox-common.dc.ssl.enabled" -}}
{{- $javaSSLEnabled := (include "ox-common.java.ssl.enabled" .) -}}
{{- $dcSSLEnabled := $javaSSLEnabled -}}
{{- if eq $javaSSLEnabled "true" -}}
  {{- if .Values -}}
    {{- if .Values.global -}}
      {{- if .Values.global.dc -}}
        {{- if .Values.global.dc.ssl -}}
          {{- $dcSSLEnabled = .Values.global.dc.ssl.enabled | default false -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $dcSSLEnabled -}}
{{- end -}}

{{/*
Provides the DC server URL depending on enabled SSL and appropriate ports and protocols
*/}}
{{- define "ox-common.dc.serverURL" -}}
{{- $scheme := (ternary "https" "http" (eq (include "ox-common.dc.ssl.enabled" .) "true")) -}}
{{- $host := (include "ox-common.dc.serviceName" .) -}}
{{- $port := (ternary 8011 8008 (eq (include "ox-common.dc.ssl.enabled" .) "true")) -}}
{{- printf "%s://%s.%s:%d/documentconverterws" $scheme $host .Release.Namespace $port -}}
{{- end -}}
