{{/*
Generates a generic jdbc URL out of a mysql data structure. If no generic host and database
have been set, it falls back to the writeHost and writeDatabase.

Input:

mysql:
    host: "mysql"
    database: "db-1"

Output:

    jdbc:mysql://mysql/db-1

Example:

   {{ include "ox-common.java.mysql.jdbcURL" .Values.mysql }}

*/}}
{{- define "ox-common.java.mysql.jdbcURL" -}}
{{ (include "ox-common.java.mysql.writeJDBCURL" . ) }}
{{- end -}}

{{/*
Generates the jdbc URL for the write database in a primary/replica setup. Uses .writeHost and .writeDatabase.
*/}}
{{- define "ox-common.java.mysql.writeJDBCURL" -}}
{{ printf "jdbc:mysql://%s:%s/%s" (include "ox-common.mysql.writeHost" . ) (include "ox-common.mysql.writePort" .)  (include "ox-common.mysql.writeDatabase" . ) }}
{{- end -}}

{{/*
Generates the jdbc URL for the read database in a primary/replica setup. Uses .readHost and .readDatabase. Falls
back to the write settings, in case no replication is set up.
*/}}

{{- define "ox-common.java.mysql.readJDBCURL" -}}
{{ printf "jdbc:mysql://%s:%s/%s" (include "ox-common.mysql.readHost" . ) (include "ox-common.mysql.readPort" .) (include "ox-common.mysql.readDatabase" . ) }}
{{- end -}}

{{/*
Functions to control the feature set of using SSL encryption for Java based services, including to access the
key- and optional truststore related data stored in a secret.

Supported configuration options to control the feature:

global:
  java:
    ssl:
      enabled: false
      secretName: <RELEASE-NAME>-java-secret
      keyStorePassword: ""
      useTrustStore: false
      trustStorePassword: ""
      keyStore: ""
      trustStore: ""

Sub-charts can provide their own configuration to disable SSL support independently of
the global configuration setting. For example look at
 _dcs.tpl where "ox-common.dcs.ssl.enabled" controls this for the DCS and MW sub-chart.
*/}}

{{/*
Generate a Java SSL secret manifest depending on the global configuration.

Usage:
{{- if and (eq (include "ox-common.java.ssl.enabled" . ) "true") -}}
{{- include "ox-common.java.ssl.createJavaSSLSecret" -}}
{{- end -}}

This code snippet must be part of the top-most stack-chart included in a separate
yaml file.
*/}}
{{- define "ox-common.java.ssl.createJavaSSLSecret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "ox-common.java.ssl.secretName" . | quote }}
type: Opaque
data:
  keystore: {{ required "A keystore is required to enable SSL for Java services! Use --set-file global.java.ssl.keyStore=<path to keystore file>" (include "ox-common.java.ssl.keyStore" . ) | b64enc }}
  keystore-password: {{ required "A keystore password is required to enable SSL for Java services!" (include "ox-common.java.ssl.keyStorePassword" . ) | b64enc }}
  {{- if eq (include "ox-common.java.ssl.useTrustStore" . ) "true" }}
  truststore: {{ required "A truststore is required, because global.java.ssl.useTrustStore is true! Use --set-file global.java.ssl.trustStore=<path to truststore file>" (include "ox-common.java.ssl.trustStore" . ) | b64enc }}
  truststore-password: {{ required "A truststore password is required if a truststore has been configured!" (include "ox-common.java.ssl.trustStorePassword" . ) | b64enc }}
  {{- end }}
{{- end -}}

{{/*
Determines if ssl should be used for Java based services.
*/}}
{{- define "ox-common.java.ssl.enabled" -}}
{{- $enabled := false -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.java -}}
      {{- if .Values.global.java.ssl -}}
        {{- $enabled = .Values.global.java.ssl.enabled | default false -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $enabled -}}
{{- end -}}

{{/*
Provides the global secret name for the key- and truststore data for Java services.
*/}}
{{- define "ox-common.java.ssl.secretName" -}}
{{- $secretName := "" -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.java }}
      {{- if .Values.global.java.ssl }}
        {{- $secretName = .Values.global.java.ssl.secretName | default "" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if empty $secretName -}}
{{- $secretName = printf "%s-%s" .Release.Name "java-secret" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- default $secretName -}}
{{- end -}}

{{/*
Provides the keystore password.
*/}}
{{- define "ox-common.java.ssl.keyStorePassword" -}}
{{- $keyStorePassword := "" -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.java -}}
      {{- if .Values.global.java.ssl -}}
        {{- $keyStorePassword = .Values.global.java.ssl.keyStorePassword | default "" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $keyStorePassword -}}
{{- end -}}

{{/*
Provides the data of the keystore.
*/}}
{{- define "ox-common.java.ssl.keyStore" -}}
{{- $keyStoreData := "" -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.java -}}
      {{- if .Values.global.java.ssl -}}
        {{- $keyStoreData = .Values.global.java.ssl.keyStore | default "" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $keyStoreData -}}
{{- end -}}

{{/*
Determines if truststore data should be used or not. Normally this is not necessary
for known CA signed certificates (inside Java default truststore).
*/}}
{{- define "ox-common.java.ssl.useTrustStore" -}}
{{- $useTrustStore := "" -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.java }}
      {{- if .Values.global.java.ssl }}
        {{- $useTrustStore = .Values.global.java.ssl.useTrustStore | default false  -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $useTrustStore -}}
{{- end -}}

{{/*
Provides the data of an optional truststore.
*/}}
{{- define "ox-common.java.ssl.trustStore" -}}
{{- $trustStoreData := "" -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.java -}}
      {{- if .Values.global.java.ssl -}}
        {{- $trustStoreData = .Values.global.java.ssl.trustStore | default "" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $trustStoreData -}}
{{- end -}}

{{/*
Provides the password of an optional truststore.
*/}}
{{- define "ox-common.java.ssl.trustStorePassword" -}}
{{- $trustStorePassword := "" -}}
{{- if .Values -}}
  {{- if .Values.global -}}
    {{- if .Values.global.java -}}
      {{- if .Values.global.java.ssl -}}
        {{- $trustStorePassword = .Values.global.java.ssl.trustStorePassword | default "" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- default $trustStorePassword -}}
{{- end -}}

{{/*
Provides the key for the keystore PEM based data stored in the java secret
*/}}
{{- define "ox-common.java.ssl.secret.keyStoreKey" -}}
{{- default "keystore" -}}
{{- end -}}

{{/*
Provides the key for the truststore PEM based data stored in the java secret
*/}}
{{- define "ox-common.java.ssl.secret.trustStoreKey" -}}
{{- default "truststore" -}}
{{- end -}}

{{/*
Provides the key for the keystore password stored in the java secret
*/}}
{{- define "ox-common.java.ssl.secret.keyStorePasswordKey" -}}
{{- default "keystore-password" -}}
{{- end -}}

{{/*
Provides the key for the truststore password stored in the java secret
*/}}
{{- define "ox-common.java.ssl.secret.trustStorePasswordKey" -}}
{{- default "truststore-password" -}}
{{- end -}}

{{/*
Generates a valueFrom structure for the keystore password to be used in the
deployment.yaml.
*/}}
{{- define "ox-common.java.ssl.secret.keyStorePassword.asValueFromSecretKeyRef" -}}
{{- $secretName := (include "ox-common.java.ssl.secretName" . ) -}}
valueFrom:
  secretKeyRef:
    name: {{ $secretName }}
    key: {{ include "ox-common.java.ssl.secret.keyStorePasswordKey" . }}
{{- end -}}

{{/*
Generates a valueFrom structure for the truststore password to be used in the
deployment.yaml.
*/}}
{{- define "ox-common.java.ssl.secret.trustStorePassword.asValueFromSecretKeyRef" -}}
{{- $secretName := (include "ox-common.java.ssl.secretName" . ) -}}
valueFrom:
  secretKeyRef:
    name: {{ $secretName }}
    key: {{ include "ox-common.java.ssl.secret.trustStorePasswordKey" . }}
{{- end -}}
