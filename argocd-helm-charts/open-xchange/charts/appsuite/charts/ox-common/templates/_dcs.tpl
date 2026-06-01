{{/*
These functions deal with dcs global settings. Global settings are:

serviceName - the service name to be used by core-documents-collaboration service
enabled - determine if the DCS service should use ssl connections or not
useInternalCerts

The input datastructure for is (with default values):

global:
  dcs:
    serviceName: {{ .Release.Name }}-"core-documents-collaboration"
    ssl:
      enabled: false
      useInternalCerts: false

The general usage to get the global dcs service name is.

Example:

env: 
    - name: DCS_SERVICENAME
      value:  {{ include "ox-common.dcs.serviceName" . }}
    - name: DCS_USE_SSL
      value: {{ include "ox-commons.dcs.useSSL" . }}

*/}}

{{/*
Generates a documents collaboration service name if none is given
*/}}
{{- define "ox-common.dcs.generateDcsServiceName" -}}
{{- printf "%s-%s" .Release.Name "core-documents-collaboration" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Provides documents collaboration service name
*/}}
{{- define "ox-common.dcs.serviceName" -}}
{{- $serviceName := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.dcs }}
    {{- $serviceName = .Values.global.dcs.serviceName -}}
  {{- end -}}
{{- end -}}
{{- $serviceName | default (include "ox-common.dcs.generateDcsServiceName" . ) -}}
{{- end -}}

{{/*
Provides the ssl config state of the documents collaboration service
*/}}
{{- define "ox-common.dcs.ssl.enabled" -}}
{{- $javaSSLEnabled := (include "ox-common.java.ssl.enabled" . ) -}}
{{- $dcsSSLEnabled := $javaSSLEnabled -}}
{{- if eq $javaSSLEnabled "true" -}}
  {{- if .Values -}}
    {{- if .Values.global -}}
      {{- if .Values.global.dcs -}}
        {{- if .Values.global.dcs.ssl -}}
          {{- $secretName := (include "ox-common.java.ssl.secretName" . ) -}}
          {{- $dcsSSLEnabled = .Values.global.dcs.ssl.enabled | default false -}}
          {{- if eq $javaSSLEnabled "true" -}}
            {{- if and $dcsSSLEnabled (empty $secretName) -}}
              {{- fail "SSL mode cannot be activated for DCS without defining 'global.java.ssl.secretName' !" -}}
            {{- end -}}
          {{- else -}}
            {{/*
            Support special mode for DCS using internal self-signed certificates for DEMO/TESTING purposes.
            */}}
            {{- $dcsSSLEnabled = (and $dcsSSLEnabled ( .Values.global.dcs.ssl.useInternalCerts | default false)) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $dcsSSLEnabled -}}
{{- end -}}

{{/*
Provides the use internal certs config state of the documents collaboration service. For DEMO and TESTING
purposes it's possible to use the internal self-signed certificates.
*/}}
{{- define "ox-common.dcs.ssl.useInternalCerts" -}}
{{- $useInternalCerts := false -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.dcs -}}
      {{- if .Values.global.dcs.ssl -}}
        {{- $useInternalCerts = .Values.global.dcs.ssl.useInternalCerts | default false -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $useInternalCerts -}}
{{- end -}}
