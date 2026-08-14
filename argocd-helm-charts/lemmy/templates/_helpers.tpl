{{/*
Override the upstream lemmy.postgresql.password helper - upstream uses lookup()
which doesn't work under ArgoCD. The placeholder is inert, LEMMY_DATABASE_URL
env provides the real connection string.
*/}}
{{- define "lemmy.postgresql.password" -}}
{{- if and (not .Values.postgresql.enabled) .Values.postgresql.auth.existingSecret -}}
CNPG_PASSWORD_PLACEHOLDER
{{- else if .Values.postgresql.auth.password -}}
{{- .Values.postgresql.auth.password -}}
{{- else if .Values.postgresql.enabled -}}
postgres
{{- else -}}
postgres
{{- end -}}
{{- end -}}
