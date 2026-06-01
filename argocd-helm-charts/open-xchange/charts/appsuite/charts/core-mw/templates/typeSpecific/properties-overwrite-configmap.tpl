{{/*
Creates a configmap with an input file for the oxprops utilty that, upon being run on container start, modifies the .properties files in /opt/open-xchange/etc. 
Properties configured here will overwrite those properties from values.yaml keys 'properties' and 'propertiesFiles'.
*/}}

{{- define "core-mw.typeSpecific.properties-overwrite-configmap.options" -}}
usedKeys: []
{{- end -}}

{{- define "core-mw.typeSpecific.properties-overwrite-configmap.template" -}}
{{- $properties := dict }}
{{- $_ := set $properties "com.openexchange.connector.awaitShutDownSeconds" .Values.terminationGracePeriodSeconds }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .ResourceName }}
data:
  997_properties_overwrite.yaml: | 
    {{- if $properties }}
    anywhere:
      {{- range $key, $value := $properties -}}
        {{- printf "%s: %s" $key ($value | quote) | nindent 6  }}
      {{- end }}
    {{- else }}
    anywhere: {}
    {{- end }}
{{- end -}}