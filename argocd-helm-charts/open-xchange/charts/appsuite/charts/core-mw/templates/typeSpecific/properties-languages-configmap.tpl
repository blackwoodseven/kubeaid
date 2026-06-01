{{/*
Creates a configmap with language properties that will be placed under /opt/open-xchange/etc/languages/appsuite/languages.properties. 
*/}}

{{- define "core-mw.typeSpecific.properties-languages-configmap.options" -}}
usedKeys:
  - configuration
{{- end -}}

{{- define "core-mw.typeSpecific.properties-languages-configmap.template" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .ResourceName }}
data:
{{ $values := .Values }}
{{ tpl (.Context.Files.Glob "config/logback.xml").AsConfig (dict "Values" $values "Template" .Context.Template) | indent 2 }}
  languages.properties: |-
{{ tpl (.Context.Files.Get "config/languages.properties") .Context | indent 4 }}
{{- end -}}