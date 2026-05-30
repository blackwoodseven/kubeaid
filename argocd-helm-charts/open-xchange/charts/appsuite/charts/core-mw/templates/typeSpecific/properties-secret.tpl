{{/*
Creates a secret with an input file for the oxprops utilty that, upon being run on container start, modifies the .properties files in /opt/open-xchange/etc.  
See values.yaml keys secretProperties and secretPropertiesFiles for example configuration
*/}}

{{- define "core-mw.typeSpecific.properties-secret.options" -}}
usedKeys:
  - secretProperties
  - secretPropertiesFiles
{{- end -}}

{{- define "core-mw.typeSpecific.properties-secret.template" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .ResourceName }}
{{- $content := include "core-mw.secretPropertiesYAML" .Values }}
{{- if $content }}
data:
  998_secret-properties.yaml: {{ $content | b64enc }}
{{- else }}
data: {}
{{- end }}
{{- end -}}
