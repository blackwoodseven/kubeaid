{{- /* Name of the shared cluster group: explicit `group`, else the
     ClusterProxy clusterName, else the router name. */}}
{{- define "kubeaid.netbirdClusterGroup" -}}
{{- .Values.group | default .Values.clusterProxy.clusterName | default .Values.networkRouter.name -}}
{{- end -}}
