{{/*
Create cacheservice-configmap name.
*/}}
{{- define "core-cacheservice.configmap" -}}
{{- printf "%s-%s" (include "ox-common.names.fullname" . | trunc 53 | trimSuffix "-") "cacheservice-configmap" }}
{{- end -}}

{{/*
Create fileItemStore name.
*/}}
{{- define "core-cacheservice.fileItemStore" -}}
  {{- printf "%s-%s" (include "ox-common.names.fullname" . | trunc 53 | trimSuffix "-") "fileitemstore" }}
{{- end -}}

{{/*
ConfigMap
*/}}
{{- define "core-cacheservice.cacheServiceConfigMap" -}}
{{- printf "%s-%s" .Release.Name "core-cacheservice" | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Definition of ObjectStoreIds for the CacheService
*/}}
{{- define "core-cacheservice.cacheService.objectStoreId" -}}
{{- if and (not .Values.cacheService.fileStores) (not .Values.cacheService.s3ObjectStores) (not .Values.cacheService.sproxydObjectStores) }}
valueFrom:
  configMapKeyRef:
      name: {{ include "core-cacheservice.cacheServiceConfigMap" . }}
      key: filestore
{{- else }}
value:
{{- end }}
{{- end -}}

{{/*
KeyStore
*/}}
{{- define "core-cacheservice.keystore" -}}
{{- printf "%s-%s" (include "ox-common.names.fullname" . | trunc 53 | trimSuffix "-") "keystore" }}
{{- end -}}
