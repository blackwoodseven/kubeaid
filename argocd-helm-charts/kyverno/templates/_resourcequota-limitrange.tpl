{{/*
  ResourceQuota "hard" for one namespace: override values win, defaults fill
  the gaps, unset keys are dropped. Returns JSON, which CEL reads as a map.
    quota:    the override's resourceQuota block (may be empty)
    defaults: .Values.resourceQuotaLimitRangeGenerator.defaults.resourceQuota
*/}}
{{- define "kubeaid.kyverno.quotaHard" -}}
{{- $q := mergeOverwrite (deepCopy .defaults) (.quota | default dict) }}
{{- $hard := dict }}
{{- with $q.pods }}{{ $_ := set $hard "pods" (toString .) }}{{ end }}
{{- with $q.jobs }}{{ $_ := set $hard "count/jobs.batch" (toString .) }}{{ end }}
{{- with $q.cpu.request }}{{ $_ := set $hard "requests.cpu" (toString .) }}{{ end }}
{{- with $q.memory.request }}{{ $_ := set $hard "requests.memory" (toString .) }}{{ end }}
{{- with $q.memory.limit }}{{ $_ := set $hard "limits.memory" (toString .) }}{{ end }}
{{- with $q.storage.persistentVolumeClaims }}{{ $_ := set $hard "persistentvolumeclaims" (toString .) }}{{ end }}
{{- with $q.storage.request }}{{ $_ := set $hard "requests.storage" (toString .) }}{{ end }}
{{- with $q.ephemeralStorage.request }}{{ $_ := set $hard "requests.ephemeral-storage" (toString .) }}{{ end }}
{{- with $q.ephemeralStorage.limit }}{{ $_ := set $hard "limits.ephemeral-storage" (toString .) }}{{ end }}
{{- toJson $hard }}
{{- end }}

{{/*
  LimitRange "limits" for one namespace, same override/default rule.
    lr:       the override's limitRange block (may be empty)
    defaults: .Values.resourceQuotaLimitRangeGenerator.defaults.limitRange
*/}}
{{- define "kubeaid.kyverno.limitRangeLimits" -}}
{{- $l := mergeOverwrite (deepCopy .defaults) (.lr | default dict) }}
{{- $limits := list
  (dict "type" "Container"
    "defaultRequest" (dict "cpu" (toString $l.container.cpu.defaultRequest) "memory" (toString $l.container.memory.defaultRequest))
    "default" (dict "memory" (toString $l.container.memory.default))
    "max" (dict "memory" (toString $l.container.memory.max)))
  (dict "type" "Pod" "max" (dict "memory" (toString $l.pod.memory.max)))
  (dict "type" "PersistentVolumeClaim" "max" (dict "storage" (toString $l.pvc.storage.max)))
}}
{{- toJson $limits }}
{{- end }}
