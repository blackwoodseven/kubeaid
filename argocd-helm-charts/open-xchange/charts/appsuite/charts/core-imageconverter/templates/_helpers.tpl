{{/*
Create ic-configmap name.
*/}}
{{- define "core-imageconverter.configmap" -}}
{{- printf "%s-%s" (include "ox-common.names.fullname" . | trunc 53 | trimSuffix "-") "ic-configmap" }}
{{- end -}}

{{/*
Create spoolDir name.
*/}}
{{- define "core-imageconverter.spoolDir" -}}
{{- printf "%s-%s" (include "ox-common.names.fullname" . | trunc 53 | trimSuffix "-") "spooldir" }}
{{- end -}}
