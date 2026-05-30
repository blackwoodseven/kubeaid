{{/*
These functions deal with redis settings. Settings are:

host - the hostname of the redis instance
database - the database id of the redis instance
username - the username used for authentication
password - the password used for authentication
mode - the operation mode (`standalone`, `cluster`, `sentinel`)
sentinelMasterId - name of the `sentinel` masterSet, if operation mode is set to `sentinel`
tls - whether to use TLS to connect to the redis instance

Use the templates defined below to set the correct values:

com.openexchange.redis.hosts={{ required "Redis host is required!" (include "ox-common.redis.hosts" (dict "redis" .Values.redis "context" .)) }}
com.openexchange.redis.username={{ include "ox-common.redis.username" (dict "redis" .Values.redis "context" .) }}
com.openexchange.redis.password={{ include "ox-common.redis.password" (dict "redis" .Values.redis "context" .) }}
{{- $redisMode := include "ox-common.redis.mode" (dict "redis" .Values.redis "context" .) }}
com.openexchange.redis.mode={{ $redisMode }}
{{- if eq "sentinel" $redisMode }}
com.openexchange.redis.sentinel.masterId={{ include "ox-common.redis.sentinelMasterId" (dict "redis" .Values.redis "context" .) }}
{{- end }}
com.openexchange.redis.tls={{ include "ox-common.redis.tls.enabled" (dict "redis" .Values.redis "context" .) }}

{{- $redisCacheEnabled := include "ox-common.redis.cache.enabled" (dict "redis" .Values.redis "context" .) }}
com.openexchange.redis.cache.enabled={{ $redisCacheEnabled }}
{{- if eq "true" $redisCacheEnabled }}
com.openexchange.redis.cache.username={{ include "ox-common.redis.cache.username" (dict "redis" .Values.redis "context" .) }}
com.openexchange.redis.cache.password={{ include "ox-common.redis.cache.password" (dict "redis" .Values.redis "context" .) }}
{{- $redisCacheMode := include "ox-common.redis.cache.mode" (dict "redis" .Values.redis "context" .) }}
com.openexchange.redis.cache.mode={{ $redisCacheMode }}
{{- if eq "sentinel" $redisCacheMode }}
com.openexchange.redis.cache.sentinel.masterId={{ include "ox-common.redis.cache.sentinelMasterId" (dict "redis" .Values.redis "context" .) }}
{{- end }}
com.openexchange.redis.cache.hosts={{ include "ox-common.redis.cache.hosts" (dict "redis" .Values.redis "context" .) }}
com.openexchange.redis.cache.tls={{ include "ox-common.redis.cache.tls.enabled" (dict "redis" .Values.redis "context" .) }}
{{- end }}

*/}}

{{- define "ox-common.redis.hosts" -}}
{{- $result := "" -}}
{{- if ((((.context).Values).global).redis).hosts -}}
{{- $result = (.redis).hosts | default .context.Values.global.redis.hosts -}}
{{- end -}}
{{- if eq "" ($result | toString) -}}
{{- $result = (.redis).hosts | default "localhost:6379" -}}
{{- end -}}
{{ $result | join "," }}
{{- end -}}

{{- define "ox-common.redis.cache.hosts" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).cache).hosts -}}
{{- $result = ((.redis).cache).hosts | default .context.Values.global.redis.cache.hosts -}}
{{- end -}}
{{- if eq "" ($result | toString) -}}
{{- $result = ((.redis).cache).hosts | default (include "ox-common.redis.hosts" (dict "redis" .context.Values.redis "context" .context)) -}}
{{- end -}}
{{ $result | join "," }}
{{- end -}}

{{- define "ox-common.redis.username" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).auth).username -}}
{{- $result = ((.redis).auth).username | default .context.Values.global.redis.auth.username -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = ((.redis).auth).username | default "" -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.cache.username" -}}
{{- $result := "" -}}
{{- if ((((((.context).Values).global).redis).cache).auth).username -}}
{{- $result = (((.redis).cache).auth).username | default .context.Values.global.redis.cache.auth.username -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = (((.redis).cache).auth).username | default (include "ox-common.redis.username" (dict "redis" .context.Values.redis "context" .context)) -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.password" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).auth).password -}}
{{- $result = (((.redis)).auth).password | default .context.Values.global.redis.auth.password -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = (((.redis)).auth).password | default "" -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.cache.password" -}}
{{- $result := "" -}}
{{- if ((((((.context).Values).global).redis).cache).auth).password -}}
{{- $result = (((.redis).cache).auth).password | default .context.Values.global.redis.cache.auth.password -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = (((.redis).cache).auth).password | default (include "ox-common.redis.password" (dict "redis" .context.Values.redis "context" .context)) -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.mode" -}}
{{- $result := "" -}}
{{- if ((((.context).Values).global).redis).mode -}}
{{- $result = (.redis).mode | default .context.Values.global.redis.mode | lower -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = (.redis).mode | lower -}}
{{- end -}}
{{ ternary $result "standalone" (has $result (list "standalone" "cluster" "sentinel")) }}
{{- end -}}

{{- define "ox-common.redis.cache.mode" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).cache).mode -}}
{{- $result = ((.redis).cache).mode | default .context.Values.global.redis.cache.mode | lower -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = ((.redis).cache).mode | default (include "ox-common.redis.mode" (dict "redis" .context.Values.redis "context" .context)) -}}
{{- end -}}
{{ ternary $result "standalone" (has $result (list "standalone" "cluster" "sentinel")) }}
{{- end -}}

{{- define "ox-common.redis.sentinelMasterId" -}}
{{- $result := "" -}}
{{- if ((((.context).Values).global).redis).sentinelMasterId -}}
{{- $result = (.redis).sentinelMasterId | default .context.Values.global.redis.sentinelMasterId -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = (.redis).sentinelMasterId | default "mymaster" -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.cache.sentinelMasterId" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).cache).sentinelMasterId -}}
{{- $result = ((.redis).cache).sentinelMasterId | default .context.Values.global.redis.cache.sentinelMasterId -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = ((.redis).cache).sentinelMasterId | default (include "ox-common.redis.sentinelMasterId" (dict "redis" .context.Values.redis "context" .context)) -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.database" -}}
{{- $result := "" -}}
{{- if ((((.context).Values).global).redis).database -}}
{{- $result = (.redis).database | default .context.Values.global.redis.database -}}
{{- $result = toString $result -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = (.redis).database | default 0 -}}
{{- $result = toString $result -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.cache.database" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).cache).database -}}
{{- $result = ((.redis).cache).database | default .context.Values.global.redis.cache.database -}}
{{- $result = toString $result -}}
{{- end -}}
{{- if eq "" $result -}}
{{- $result = ((.redis).cache).database | default (include "ox-common.redis.database" (dict "redis" .context.Values.redis "context" .context)) -}}
{{- $result = toString $result -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.cache.enabled" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).cache).enabled -}}
{{- $result = ((.redis).cache).enabled | default .context.Values.global.redis.cache.enabled -}}
{{- end -}}
{{- if eq "" ($result | toString) -}}
{{- $result = ((.redis).cache).enabled | default "false" -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.tls.enabled" -}}
{{- $result := "" -}}
{{- if (((((.context).Values).global).redis).tls).enabled -}}
{{- $result = ((.redis).tls).enabled | default .context.Values.global.redis.tls.enabled -}}
{{- end -}}
{{- if eq "" ($result | toString) -}}
{{- $result = ((.redis).tls).enabled | default "false" -}}
{{- end -}}
{{ $result }}
{{- end -}}

{{- define "ox-common.redis.cache.tls.enabled" -}}
{{- $result := "" -}}
{{- if ((((((.context).Values).global).redis).cache).tls).enabled -}}
{{- $result = (((.redis).cache).tls).enabled | default .context.Values.global.redis.cache.tls.enabled -}}
{{- end -}}
{{- if eq "" ($result | toString) -}}
{{- $result = (((.redis).cache).tls).enabled | default "false" -}}
{{- end -}}
{{ $result }}
{{- end -}}