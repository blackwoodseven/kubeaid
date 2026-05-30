{{/*
Creates a configmap with an input file for the oxprops utilty that, upon being run on container start, modifies the .properties files in /opt/open-xchange/etc/settings 
containing properties for the jslob configuration for the UI.  
See values.yaml keys uiSettings and uiSettingsFiles for example configuration
*/}}

{{- define "core-mw.typeSpecific.ui-settings-configmap.options" -}}
usedKeys:
  - uiSettings
  - uiSettingsFiles
{{- end -}}

{{- define "core-mw.typeSpecific.ui-settings-configmap.template" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .ResourceName }}
data:
  1999_ui-overrides.yaml: |
  {{- if .Values.uiSettings }}
    /opt/open-xchange/etc/settings/overrides.properties:
    {{- range $key, $value := (default dict .Values.uiSettings) }}
      {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
  {{- range $filename, $contentMap := .Values.uiSettingsFiles }}
    {{ $filename }}:
    {{- range $key, $value := (default dict $contentMap) }}
      {{ $key }}: {{ $value | quote }}
    {{- end }}
  {{- end }}
{{- end -}}
