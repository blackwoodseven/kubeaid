{{/*
These functions deal with Spellcheck global settings. Global settings are:

serviceName - the service name to be used by Spellcheck service
enabled - determine if the Spellcheck service should use ssl connections or not

The input datastructure for Spellcheck is (with default values):

global:
  spellcheck:
    serviceName: {{ .Release.Name }}-"core-spellcheck"
    openssl:
      enabled: false

The general usage to get the global Spellcheck service name is.

Example:

env:
    - name: SPELLCHECK_SERVICENAME
      value:  {{ include "ox-common.spellcheck.serviceName" . }}
    - name: SPELLCHECK_USE_OPENSSL
      value: {{ include "ox-commons.spellcheck.useOpenSSL" . }}
    - name: SPELLCHECK_SERVER_URL
      value: {{ include "ox-common.spellcheck.serverURL" . }}
*/}}

{{/*
Generates a Spellcheck service name if none is given
*/}}
{{- define "ox-common.spellcheck.generateSpellcheckServiceName" -}}
{{- printf "%s-%s" .Release.Name "core-spellcheck" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Provides Spellcheck service name
*/}}
{{- define "ox-common.spellcheck.serviceName" -}}
{{- $serviceName := "" -}}
{{- if .Values.global -}}
  {{- if .Values.global.spellcheck }}
    {{- $serviceName = .Values.global.spellcheck.serviceName -}}
  {{- end -}}
{{- end -}}
{{- $serviceName | default (include "ox-common.spellcheck.generateSpellcheckServiceName" . ) -}}
{{- end -}}

{{/*
Provides the ssl config state of the Spellcheck
*/}}
{{- define "ox-common.spellcheck.openssl.enabled" -}}
{{- $openSSLEnabled := (include "ox-common.openssl.enabled" .) -}}
{{- $spellcheckSSLEnabled := $openSSLEnabled -}}
{{- if eq $openSSLEnabled "true" -}}
  {{- if .Values -}}
    {{- if .Values.global -}}
      {{- if .Values.global.spellcheck -}}
        {{- if .Values.global.spellcheck.openssl -}}
          {{- $spellcheckSSLEnabled = .Values.global.spellcheck.openssl.enabled | default false -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $spellcheckSSLEnabled -}}
{{- end -}}

{{/*
Provides the Spellcheck server URL depending on enabled OpenSSL and appropriate ports and protocols
*/}}
{{- define "ox-common.spellcheck.serverURL" -}}
{{- if eq (include "ox-common.spellcheck.openssl.enabled" .) "true" -}}
  {{- (printf "https://%s.%s:8003" (include "ox-common.spellcheck.serviceName" .) .Release.Namespace)  | trimSuffix "-"  -}}
{{- else -}}
  {{- (printf "http://%s.%s:8003" (include "ox-common.spellcheck.serviceName" .) .Release.Namespace) | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
