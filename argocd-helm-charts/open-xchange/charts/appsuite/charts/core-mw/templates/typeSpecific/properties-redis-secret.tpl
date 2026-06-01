{{/*
Creates a secret with Redis properties.
*/}}

{{- define "core-mw.typeSpecific.properties-redis-secret.options" -}}
usedKeys:
  - redis
{{- end -}}

{{- define "core-mw.typeSpecific.properties-redis-secret.template" -}}
{{- if not .Values.redis.existingSecret }}
{{-   $properties := dict }}
{{-   $_ := set $properties "com.openexchange.redis.hosts" (required "Redis host is required!" (include "ox-common.redis.hosts" (dict "redis" .Values.redis "context" .))) }}
{{-   $_ := set $properties "com.openexchange.redis.username" (include "ox-common.redis.username" (dict "redis" .Values.redis "context" .)) }}
{{-   $_ := set $properties "com.openexchange.redis.password" (include "ox-common.redis.password" (dict "redis" .Values.redis "context" .)) }}
{{-   $redisMode := include "ox-common.redis.mode" (dict "redis" .Values.redis "context" .) }}
{{-   $_ := set $properties "com.openexchange.redis.mode" $redisMode }}
{{-   if eq "sentinel" $redisMode }}
{{-     $_ := set $properties "com.openexchange.redis.sentinel.masterId" (include "ox-common.redis.sentinelMasterId" (dict "redis" .Values.redis "context" .)) }}
{{-   end }}
{{-   $_ := set $properties "com.openexchange.redis.ssl" (include "ox-common.redis.tls.enabled" (dict "redis" .Values.redis "context" .)) }}
{{-   $redisCacheEnabled := include "ox-common.redis.cache.enabled" (dict "redis" .Values.redis "context" .) }}
{{-   $_ := set $properties "com.openexchange.redis.cache.enabled" $redisCacheEnabled }}
{{-   if eq "true" $redisCacheEnabled }}
{{-     $_ := set $properties "com.openexchange.redis.cache.username" (include "ox-common.redis.cache.username" (dict "redis" .Values.redis "context" .)) }}
{{-     $_ := set $properties "com.openexchange.redis.cache.password" (include "ox-common.redis.cache.password" (dict "redis" .Values.redis "context" .)) }}
{{-     $redisCacheMode := include "ox-common.redis.cache.mode" (dict "redis" .Values.redis "context" .) }}
{{-     $_ := set $properties "com.openexchange.redis.cache.mode" $redisCacheMode }}
{{-     if eq "sentinel" $redisCacheMode }}
{{-       $_ := set $properties "com.openexchange.redis.cache.sentinel.masterId" (include "ox-common.redis.cache.sentinelMasterId" (dict "redis" .Values.redis "context" .)) }}
{{-     end }}
{{-     $_ := set $properties "com.openexchange.redis.cache.hosts" (required "Redis host is required!" (include "ox-common.redis.cache.hosts" (dict "redis" .Values.redis "context" .))) }}
{{-     $_ := set $properties "com.openexchange.redis.cache.ssl" (include "ox-common.redis.cache.tls.enabled" (dict "redis" .Values.redis "context" .)) }}
{{-   end }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .ResourceName }}
stringData:
  1000_redis-properties.yaml: | 
    anywhere:
      {{- range $key, $value := $properties -}}
      {{-   printf "%s: %s" $key ($value | quote) | nindent 6  }}
      {{- end }}
{{- end }}
{{- end -}}