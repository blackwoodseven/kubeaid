{{/*
Enabled instances as one list: the single global.mongodb block plus every
enabled entry of global.mongodb.instances.
*/}}
{{- define "kubeaid-addons.mongodb.instances" -}}
{{- $instances := list -}}
{{- if (((.Values.global).mongodb).enabled) -}}
{{- $instances = append $instances .Values.global.mongodb -}}
{{- end -}}
{{- range (((.Values.global).mongodb).instances) -}}
{{- if .enabled -}}
{{- $instances = append $instances . -}}
{{- end -}}
{{- end -}}
{{- $instances | toJson -}}
{{- end -}}

{{/*
Distinct ServiceAccount names across enabled instances, one RBAC set each.
"mongodb-kubernetes-appdb" is always included: the MongoDB Controllers for
Kubernetes operator forces that name onto the StatefulSet regardless of the
CR, and without it the recreated pod is rejected as not found.
*/}}
{{- define "kubeaid-addons.mongodb.serviceAccountNames" -}}
{{- $instances := include "kubeaid-addons.mongodb.instances" . | fromJsonArray -}}
{{- $names := list -}}
{{- if $instances -}}
{{- $names = append $names "mongodb-kubernetes-appdb" -}}
{{- end -}}
{{- range $instances -}}
{{- $names = append $names (.serviceAccountName | default "mongodb-kubernetes-appdb") -}}
{{- end -}}
{{- $names | uniq | toJson -}}
{{- end -}}

{{/*
Entries with logicalbackup.enabled, independent of `enabled`, so an
externally managed MongoDBCommunity can still be backed up.
*/}}
{{- define "kubeaid-addons.mongodb.backupTargets" -}}
{{- $targets := list -}}
{{- if (((.Values.global).mongodb).logicalbackup).enabled -}}
{{- $targets = append $targets .Values.global.mongodb -}}
{{- end -}}
{{- range (((.Values.global).mongodb).instances) -}}
{{- if (.logicalbackup).enabled -}}
{{- $targets = append $targets . -}}
{{- end -}}
{{- end -}}
{{- $targets | toJson -}}
{{- end -}}
