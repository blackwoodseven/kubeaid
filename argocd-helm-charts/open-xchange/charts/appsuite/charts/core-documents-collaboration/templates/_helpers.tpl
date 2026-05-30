{{/*
Create dcs-configmap name.
*/}}
{{- define "core-documents-collaboration.configmap" -}}
{{- printf "%s-%s" (include "ox-common.names.fullname" . | trunc 53 | trimSuffix "-") "dcs-configmap" }}
{{- end -}}
