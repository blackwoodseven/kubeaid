{{- /* This cluster's identity on the NetBird Management — the router + proxy
     names and the two chart-created groups all derive from it. */ -}}
{{- define "kubeaid.netbirdClusterName" -}}
{{- required "netbird-operator: clusterName is required when networkRouter or clusterProxy is enabled — this cluster's unique, lowercase name on the NetBird Management (it replaced the old group:, networkRouter.name and clusterProxy.clusterName keys)." .Values.clusterName -}}
{{- end -}}

{{- /* Group holding this cluster's peers + resources (policy destination). */ -}}
{{- define "kubeaid.netbirdClusterGroup" -}}
{{- printf "k8s-%s" (include "kubeaid.netbirdClusterName" .) -}}
{{- end -}}
