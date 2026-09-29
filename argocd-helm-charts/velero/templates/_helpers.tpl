{{/*
Shared body for every Schedule in velero-schedules.yaml. Takes the root context plus
this schedule's ttl and, optionally, a storageLocation - so adding a schedule there is
a few lines rather than another copy of this block.
*/}}
{{- define "velero.scheduleTemplate" -}}
template:
  hooks: {}
  resourcePolicy:
    kind: configmap
    name: cnpg-skip-volumes
  csiSnapshotTimeout: {{ .root.Values.schedule.csiSnapshotTimeout | default "40m" }}
  itemOperationTimeout: 300m
  includedNamespaces:
  {{- if .root.Values.schedule.includedNamespaces }}
  {{- toYaml .root.Values.schedule.includedNamespaces | nindent 4 }}
  {{- else }}
    - "*"
  {{- end }}
  {{- if .root.Values.schedule.excludedResources }}
  excludedResources:
  {{- toYaml .root.Values.schedule.excludedResources | nindent 4 }}
  {{- end }}
  {{- if .storageLocation }}
  storageLocation: {{ .storageLocation }}
  {{- end }}
  ttl: {{ .ttl }}
  metadata:
    labels:
      argocd.argoproj.io/instance: velero
{{- end -}}
