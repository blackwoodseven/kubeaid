{{/*
Creates a secret with an input file containing sensitive configuratio for the oxprops utilty that, upon being run on container start, modifies the .properties files in /opt/open-xchange/etc/settings 
containing properties for the jslob configuration for the UI.  
See values.yaml keys secretUISettings and secretUISettingsFiles for example configuration
*/}}

{{- define "core-mw.typeSpecific.ui-settings-secret.options" -}}
usedKeys:
  - secretUISettings
  - secretUISettingsFiles
{{- end -}}

{{- define "core-mw.typeSpecific.ui-settings-secret.template" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .ResourceName }}
{{- $content := include "core-mw.secretUIPropertiesYAML" .Values }}
{{- if $content }}
data:
  2000_secret-ui-overrides.yaml: {{ $content | b64enc }}
{{- else }}
data: {}
{{- end }}
{{- end -}}
