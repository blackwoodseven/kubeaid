{{/*
Determines if a service account should get created. This is the case when `.Values.serviceAccountName` is empty or `serviceAccount.create` is `true`.

Example:
{{- if eq (include "ox-common.serviceaccount.create" (dict "podRoot" .Values "context" . "global" $)) "true" }}
...
{{- end }}

*/}}
{{- define "ox-common.serviceaccount.create" -}}
{{- $podRoot := .podRoot -}}
{{- if ($podRoot.serviceAccount).create -}}
true
{{- else -}}
false
{{- end }}
{{- end -}}

{{/*
Determines the name of a service account. The service account name is

- the value of `.Values.serviceAccountName`
- if `.Values.serviceAccountName` is empty and `.Values.serviceAccount.create` is `true` the service accout name will be a combination
  of `.Release.Name` and `.Values.serviceAccount.name`.
- otherwise the default service account name will be used.

Example:
serviceAccountName: {{- print (include "ox-common.serviceaccount.name" (dict "podRoot" .Values "context" . "global" $)) }}

*/}}
{{- define "ox-common.serviceaccount.name" -}}
{{- $podRoot := .podRoot -}}
{{- $context := .context -}}
{{- $global := .global -}}
{{- if $podRoot.serviceAccountName -}}
{{ print $podRoot.serviceAccountName }}
{{- else -}}
{{- if ($podRoot.serviceAccount).create -}}
{{- default (include "ox-common.names.fullname" $context) $podRoot.serviceAccount.name }}
{{- else -}}
default
{{- end }}
{{- end -}}
{{- end -}}
