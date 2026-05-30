{{/*
Creates a configmap with an input file for the oxprops utilty that, upon being run on container start, modifies the .properties files in /opt/open-xchange/etc.  
See values.yaml keys properties and propertiesFiles for example configuration
*/}}

{{- define "core-mw.typeSpecific.properties-configmap.options" -}}
usedKeys:
  - properties
  - propertiesFiles
{{- end -}}

{{- define "core-mw.typeSpecific.properties-configmap.template" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .ResourceName }}
data:
  996_properties.yaml: | 
    anywhere: {{ toYaml (default dict .Values.properties) | nindent 6 }} {{ printf "\n    " }}
{{- range $filename, $contentMap := .Values.propertiesFiles -}}
    {{ $filename }}: {{ toYaml (default dict $contentMap) | nindent 6 }} {{ printf "\n    " }}
{{- end }}  
{{- end -}}
