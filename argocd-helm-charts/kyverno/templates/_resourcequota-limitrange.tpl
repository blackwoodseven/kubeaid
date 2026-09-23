{{/*
  Build the ResourceQuota "hard" map for one namespace: override values win,
  defaults fill the gaps, empty keys are dropped. Returns JSON, which is also
  a valid CEL map literal.
    quota:    the override's resourceQuota block (may be empty)
    defaults: .Values.resourceQuotaLimitRangeGenerator.defaults.resourceQuota
*/}}
{{- define "kubeaid.kyverno.quotaHard" -}}
{{- $q := .quota | default dict }}
{{- $d := .defaults }}
{{- $hard := dict }}
{{- with ($q.pods | default $d.pods) }}{{ $_ := set $hard "pods" (toString .) }}{{ end }}
{{- with ($q.jobs | default $d.jobs) }}{{ $_ := set $hard "count/jobs.batch" (toString .) }}{{ end }}
{{- with ((($q.cpu).request) | default $d.cpu.request) }}{{ $_ := set $hard "requests.cpu" (toString .) }}{{ end }}
{{- with ((($q.memory).request) | default $d.memory.request) }}{{ $_ := set $hard "requests.memory" (toString .) }}{{ end }}
{{- with ((($q.memory).limit) | default $d.memory.limit) }}{{ $_ := set $hard "limits.memory" (toString .) }}{{ end }}
{{- with ((($q.storage).persistentVolumeClaims) | default $d.storage.persistentVolumeClaims) }}{{ $_ := set $hard "persistentvolumeclaims" (toString .) }}{{ end }}
{{- with ((($q.storage).request) | default $d.storage.request) }}{{ $_ := set $hard "requests.storage" (toString .) }}{{ end }}
{{- with ((($q.ephemeralStorage).request) | default $d.ephemeralStorage.request) }}{{ $_ := set $hard "requests.ephemeral-storage" (toString .) }}{{ end }}
{{- with ((($q.ephemeralStorage).limit) | default $d.ephemeralStorage.limit) }}{{ $_ := set $hard "limits.ephemeral-storage" (toString .) }}{{ end }}
{{- toJson $hard }}
{{- end }}

{{/*
  Build the LimitRange "limits" list for one namespace, same override/default rule.
    lr:       the override's limitRange block (may be empty)
    defaults: .Values.resourceQuotaLimitRangeGenerator.defaults.limitRange
*/}}
{{- define "kubeaid.kyverno.limitRangeLimits" -}}
{{- $l := .lr | default dict }}
{{- $d := .defaults }}
{{- $limits := list
  (dict "type" "Container"
    "defaultRequest" (dict
      "cpu" (toString ((((($l.container).cpu).defaultRequest)) | default $d.container.cpu.defaultRequest))
      "memory" (toString ((((($l.container).memory).defaultRequest)) | default $d.container.memory.defaultRequest)))
    "default" (dict
      "memory" (toString ((((($l.container).memory).default)) | default $d.container.memory.default)))
    "max" (dict
      "memory" (toString ((((($l.container).memory).max)) | default $d.container.memory.max))))
  (dict "type" "Pod"
    "max" (dict
      "memory" (toString (((($l.pod).memory).max) | default $d.pod.memory.max))))
  (dict "type" "PersistentVolumeClaim"
    "max" (dict
      "storage" (toString (((($l.pvc).storage).max) | default $d.pvc.storage.max))))
}}
{{- toJson $limits }}
{{- end }}
