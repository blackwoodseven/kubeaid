{{/*
Creates a configmap containing environment variables for the middleware pods. See the code itself for a list of env variables and values.
This is used in as an envFrom source by the middleware pods.
*/}}

{{- define "core-mw.typeSpecific.secret-envvars.options" -}}
usedKeys:
  - credstoragePasscrypt
  - masterAdmin
  - masterPassword
  - basicAuthLogin
  - jolokiaLogin
  - jolokiaPassword
{{- end -}}

{{- define "core-mw.typeSpecific.secret-envvars.template" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .ResourceName }}
  namespace: {{ .Context.Release.Namespace | quote }}
  labels:
    {{- include "ox-common.labels.standard" .Context | nindent 4 }}
type: Opaque
data:
  CREDSTORAGE_PASSCRYPT: {{ .Values.credstoragePasscrypt | b64enc }}
  MASTER_ADMIN_USER: {{ .Values.masterAdmin | b64enc }}
  MASTER_ADMIN_PW: {{ .Values.masterPassword | b64enc }}
  OX_BASIC_AUTH_LOGIN: {{ .Values.basicAuthLogin | b64enc }}
  OX_BASIC_AUTH_PASSWORD: {{ .Values.basicAuthPassword | b64enc }}
  JOLOKIA_LOGIN: {{ .Values.jolokiaLogin | b64enc }}
  JOLOKIA_PASSWORD: {{ .Values.jolokiaPassword | b64enc }}
{{- if and (eq (include "ox-common.dcs.ssl.enabled" .Context) "true") }}
{{-   if eq (include "ox-common.dcs.ssl.useInternalCerts" .Context) "true" }}
  DCS_USEINTERNALCERTS: {{ include "ox-common.dcs.ssl.useInternalCerts" .Context | toString | b64enc }}
{{-   else }}
  DCS_SSL_CLIENT_KEYSTORE_PASSWORD: {{ include "ox-common.java.ssl.keyStorePassword" .Context | b64enc }}
  DCS_SSL_CLIENT_KEYSTORE_PATH: {{ "/opt/open-xchange/etc/security/java-ssl.ks" | b64enc }}
{{-     if eq (include "ox-common.java.ssl.useTrustStore" .Context) "true" }}
  DCS_SSL_CLIENT_TRUSTSTORE_PASSWORD: {{ include "ox-common.java.ssl.trustStorePassword" .Context | b64enc }}
  DCS_SSL_CLIENT_TRUSTSTORE_PATH: {{ "/opt/open-xchange/etc/security/java-ssl.ts" | b64enc }}
{{-     end }}
{{-   end }}
{{- end }}
{{- end -}}
