{{/*
These functions deal with appsuite global settings. Global settings are:

appRoot - the root path of the URL to reach Appsuite frontend and backend services.
cookieHashSalt - cookie hash salt to avoid a potential brute force attack to cookie hashes. 
shareCryptKey - defines a key that is used to encrypt the password/pin of anonymously accessible shares in the database.
sessiondEncryptionKey - key to encrypt passwords during transmission during session migration.

The input datastructure for this is:

global:
  appsuite:
    appRoot: "/appsuite"
    cookieHashSalt: "KtLUTLKZrbXvCAOn"
    shareCryptKey: "lJZEFPzUYfapWbXL"
    sessiondEncryptionKey: "auw948cz,spdfgibcsp9e8ri+<#qawcghgifzign7c6gnrns9oysoeivn"
*/}}

{{/*
Retrieves the Appsuite appRoot path (default: "/appsuite").

Example:

properties:
    com.openexchange.UIWebPath: "{{ include "ox-common.appsuite.appRoot" . }}/"
*/}}
{{- define "ox-common.appsuite.appRoot" -}}
{{- $appRoot := "/appsuite" }}
{{- if (((.Values).global).appsuite).appRoot }}
  {{- $appRoot = .Values.global.appsuite.appRoot }}
{{- end -}}
{{- if (eq $appRoot "") -}}
  {{- $appRoot = "" -}}
{{- else if (eq $appRoot "/") -}}
  {{- $appRoot = "" -}}
{{- else if (ne $appRoot "") -}}
  {{- if (ne (substr 0 1 $appRoot) "/") -}}
    {{- fail (printf ".Values.global.appsuite.appRoot must start with '/', '%s'" .Values.global.appsuite.appRoot) }}
  {{- end -}}
  {{- if (eq (substr (int (sub (int64 (len $appRoot)) (int64 1))) (len $appRoot) $appRoot) "/") -}}
    {{- fail (printf ".Values.global.appsuite.appRoot must not end with '/', got '%s'" .Values.global.appsuite.appRoot) }}
  {{- end -}}
{{- end -}}
{{- $appRoot -}}
{{- end -}}

{{/*
Provides a <RELEASE>-common-env secret containing sensitive environment variables, that are shared between services and need to be the same across the cluster.

Example:

apiVersion: v1
kind: Secret
metadata:
  {...}
data:
  COOKIE_HASH_SALT: S3RMVVRMS1pyYlh2Q0FPbg==
  SESSIOND_ENCRYPTION_KEY: YXV3OTQ4Y3osc3BkZmdpYmNzcDllOHJpKzwjcWF3Y2doZ2lmemlnbjdjNmducm5zOW95c29laXZu
  SHARE_CRYPT_KEY: bEpaRUZQelVZZmFwV2JYTA==

Variables that are already set in an existing secret with name '<RELEASE>-common-env' take precedence over values specified in the appsuite global section.

If a variable is neither specified in the appsuite global section nor in a Secret with name '<RELEASE>-common-env', an auto-generated random value will be written into the Secret.
*/}}
{{- define "ox-common.appsuite.commonEnv" -}}
{{- $cookieHashSalt := randAlphaNum 16 -}}
{{- $shareCryptKey := randAlphaNum 12 -}}
{{- $sessiondEncryptionKey := randAlphaNum 58 -}}
{{- if (((.Values).global).appsuite).cookieHashSalt -}}
{{- $cookieHashSalt = .Values.global.appsuite.cookieHashSalt -}}
{{- end -}}
{{- if (((.Values).global).appsuite).shareCryptKey -}}
{{- $shareCryptKey = .Values.global.appsuite.shareCryptKey -}}
{{- end -}}
{{- if (((.Values).global).appsuite).sessiondEncryptionKey -}}
{{- $sessiondEncryptionKey = .Values.global.appsuite.sessiondEncryptionKey -}}
{{- end -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (printf "%s-common-env" .Release.Name)) -}}
{{- if (($secret).data).COOKIE_HASH_SALT -}}
{{- $cookieHashSalt = index $secret.data.COOKIE_HASH_SALT | b64dec -}}
{{- end -}}
{{- if (($secret).data).SHARE_CRYPT_KEY -}}
{{- $shareCryptKey = index $secret.data.SHARE_CRYPT_KEY | b64dec -}}
{{- end -}}
{{- if (($secret).data).SESSIOND_ENCRYPTION_KEY -}}
{{- $sessiondEncryptionKey = index $secret.data.SESSIOND_ENCRYPTION_KEY | b64dec -}}
{{- end -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-common-env
  namespace: {{ .Release.Namespace }}
  annotations:
    helm.sh/resource-policy: "keep"
  labels:
    helm.sh/chart: {{ include "ox-common.names.chart" . }}
data:
  COOKIE_HASH_SALT: {{ $cookieHashSalt | b64enc }}
  SHARE_CRYPT_KEY: {{ $shareCryptKey | b64enc }}
  SESSIOND_ENCRYPTION_KEY: {{ $sessiondEncryptionKey | b64enc }}
{{- end -}}
