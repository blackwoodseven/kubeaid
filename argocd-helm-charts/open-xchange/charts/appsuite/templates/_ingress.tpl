{{- define "appsuite.ingress.plainIngress" -}}
{{- $routeConfig := (get .Context.Values.ingress.routes .Name) -}}
{{- $arguments := . -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name:  {{ include "ox-common.names.fullname" .Context }}-{{ .Name }}
{{- if  $routeConfig.annotations }}
  annotations: {{ $routeConfig.annotations | toYaml | nindent 4 }}
  {{- if .Context.Values.ingress.annotations }}
  {{ .Context.Values.ingress.annotations | toYaml | nindent 4}}
  {{- end -}}
{{- else if .Context.Values.ingress.annotations }}
  annotations: {{ .Context.Values.ingress.annotations | toYaml | nindent 4}}
{{- end }}
spec:
  {{ include "appsuite.ingress.ingressClass" (dict "RouteConfig" $routeConfig "Context" .Context) }}
{{- if .TLS.enabled }}
  tls:
  - hosts:
{{- range $arguments.Hosts }}
    - {{ . | quote }}
{{- end }}
    secretName: {{ $arguments.TLS.existingSecret }}
{{- end }}
  rules:
{{- range $arguments.Hosts }}
  - host: {{ . }}
    http:
      paths:
{{- range $arguments.Paths }}
{{ include "appsuite.ingress.path" (dict "Path" . "Context" $arguments.Context "PortNumber" $arguments.PortNumber) | indent 8 }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "appsuite.ingress.path" -}}
{{- $path := .Path -}}
{{- $context := .Context -}}
- path: {{ $path.Path }}
  pathType: {{ $path.PathType }}
  {{- if $path.Service }}
  backend:
    service:
      name: {{ $context.Release.Name }}-{{ $path.Service }}
      port:
        number: {{ $path.PortNumber }}
  {{- else }}
  backend:
    service:
      name: {{ $context.Release.Name }}-core-ui-middleware
      port:
        number: 80
  {{- end }}
{{- end -}}

{{- define "appsuite.ingress.ingressClass" -}}
{{- if .RouteConfig.ingressClassName -}}
ingressClassName: {{ .RouteConfig.ingressClassName }}
{{- else if .Context.Values.ingress.ingressClassName  -}}
ingressClassName: {{ .Context.Values.ingress.ingressClassName }}
{{- end -}}
{{- end -}}

{{- define "appsuite.ingress.sticky" -}}
{{- $routeConfig := (get .Context.Values.ingress.routes .Name) -}}
{{- $arguments := deepCopy . -}}
{{- $_ := set $arguments "RouteConfig" $routeConfig -}}
{{- $adapter := .Context.Values.ingress.adapter | default "appsuite.ingress.ingress-nginx" -}}
{{ include (printf "%s.sticky" $adapter ) $arguments }}
{{- end -}}

{{- define "appsuite.ingress.redirect" -}}
{{- $adapter := .Context.Values.ingress.adapter | default "appsuite.ingress.ingress-nginx" -}}
{{- $routeConfig := (get .Context.Values.ingress.routes .Name) -}}
{{- $arguments := deepCopy . -}}
{{- $_ := set $arguments "RouteConfig" $routeConfig -}}
{{ include (printf "%s.redirect" $adapter ) $arguments }}
{{- end -}}

{{- define "appsuite.ingress.rewrite" -}}
{{- $routeConfig := (get .Context.Values.ingress.routes .Name) -}}
{{- $arguments := deepCopy . -}}
{{- $_ := set $arguments "RouteConfig" $routeConfig -}}
{{- $adapter := .Context.Values.ingress.adapter | default "appsuite.ingress.ingress-nginx" -}}
{{ include (printf "%s.rewrite" $adapter ) $arguments }}
{{- end -}}

{{/* Ingress-NGINX Adapter (  https://github.com/kubernetes/ingress-nginx/tree/main ) */}}

{{- define "appsuite.ingress.ingress-nginx.sticky.annotations" -}}
nginx.ingress.kubernetes.io/affinity: cookie
nginx.ingress.kubernetes.io/session-cookie-name: {{ .Name }}
nginx.ingress.kubernetes.io/session-cookie-change-on-failure: "true"
{{- end -}}

{{- define "appsuite.ingress.ingress-nginx.sticky" -}}
{{- $path := .Path -}}
{{- $_ := set $path "PathType" "ImplementationSpecific" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name:  {{ include "ox-common.names.fullname" .Context }}-{{ .Name }}
{{- if eq .RouteConfig.annotationMode "Replace" }}
  annotations: {{ .RouteConfig.annotations | toYaml | nindent 4}}
  {{- if .Context.Values.ingress.annotations }}
  {{ .Context.Values.ingress.annotations | toYaml | nindent 4}}
  {{- end -}}
{{- else }}
  annotations: {{ include "appsuite.ingress.ingress-nginx.sticky.annotations" .Path.StickyDestination | nindent 4 }}
  {{- if .RouteConfig.annotations }}
  {{ .RouteConfig.annotations | toYaml | nindent 4}}
  {{- end -}}
  {{- if .Context.Values.ingress.annotations }}
  {{ .Context.Values.ingress.annotations | toYaml | nindent 4}}
  {{- end -}}
{{- end }}
spec:
  {{ include "appsuite.ingress.ingressClass" . }}
{{- if .TLS.enabled }}
  tls:
  - hosts:
{{- range .Hosts }}
    - {{ . | quote }}
{{- end }}
    secretName: {{ .TLS.existingSecret }}
{{- end }}
  rules:
{{- $Path := .Path -}}
{{- $Context := .Context -}}
{{- range .Hosts }}
  - host: {{ . }}
    http:
      paths:
{{ include "appsuite.ingress.path" (dict "Path" $Path "Context" $Context) | indent 8 }}
{{- end -}}
{{- end -}}

{{- define "appsuite.ingress.ingress-nginx.redirect" -}}
{{- $path := deepCopy .Path -}}
{{- $_ := set $path "PathType" "ImplementationSpecific" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name:  {{ include "ox-common.names.fullname" .Context }}-{{ .Name }}
{{- if eq .RouteConfig.annotationMode "Replace" }}
  annotations: {{ .RouteConfig.annotations | toYaml | nindent 4}}
{{- else }}
  annotations: 
{{- if eq $path.Path "/" }}
    nginx.ingress.kubernetes.io/app-root: {{ .Path.Redirect }}
{{- else }}
    nginx.ingress.kubernetes.io/temporal-redirect: {{ .Path.Redirect }}
{{- end }}
  {{- if .RouteConfig.annotations }}
  {{ .RouteConfig.annotations | toYaml | nindent 4}}
  {{- end -}}
  {{- if .Context.Values.ingress.annotations }}
  {{ .Context.Values.ingress.annotations | toYaml | nindent 4}}
  {{- end -}}
{{- end }}
spec:
  {{ include "appsuite.ingress.ingressClass" . }}
{{- if .TLS.enabled }}
  tls:
  - hosts:
{{- range .Hosts }}
    - {{ . | quote }}
{{- end }}
    secretName: {{ .TLS.existingSecret }}
{{- end }}
  rules:
{{- $Context := .Context -}}
{{- range .Hosts }}
  - host: {{ . }}
    http:
      paths:
{{ include "appsuite.ingress.path" (dict "Path" $path "Context" $Context) | indent 8 }}
{{- end -}}
{{- end -}}

{{- define "appsuite.ingress.ingress-nginx.rewrite" -}}
{{- $path := .Path -}}
{{/* /* append (/|$)(.*) so we can use capture group 2 in regex see: https://kubernetes.github.io/ingress-nginx/examples/rewrite/ */}}
{{- $_ := set .Path "Path" (printf "%s(.*)" $path.Path) -}}
{{- $_ := set .Path "PathType" "ImplementationSpecific" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name:  {{ include "ox-common.names.fullname" .Context }}-{{ .Name }}
{{- if eq .RouteConfig.annotationMode "Replace" }}
  annotations: {{ .RouteConfig.annotations | toYaml | nindent 4}}
{{- else }}
  annotations: 
    nginx.ingress.kubernetes.io/rewrite-target: {{ .Path.Rewrite }}$1
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/affinity: cookie
    nginx.ingress.kubernetes.io/session-cookie-name: {{ .Name }}
    nginx.ingress.kubernetes.io/session-cookie-path: /
    nginx.ingress.kubernetes.io/session-cookie-change-on-failure: "true"
    {{- if .RouteConfig.timeout }}
    nginx.ingress.kubernetes.io/proxy-read-timeout: "{{ .RouteConfig.timeout | default "60s" }}"
    {{- end -}}
    {{- if .RouteConfig.annotations -}}
    {{ .RouteConfig.annotations | toYaml | nindent 4}}
    {{- end -}}
    {{- if .Context.Values.ingress.annotations }}
    {{ .Context.Values.ingress.annotations | toYaml | nindent 4}}
    {{- end -}}
{{- end }}
{{- if .StickyDestination -}}
{{ include "appsuite.ingress.ingress-nginx.sticky.annotations" .Path.StickyDestination | nindent 4 }}
{{- end }}
spec:
  {{ include "appsuite.ingress.ingressClass" . }}
{{- if .TLS.enabled }}
  tls:
  - hosts:
{{- range .Hosts }}
    - {{ . | quote }}
{{- end }}
    secretName: {{ .TLS.existingSecret }}
{{- end }}
  rules:
{{- $Path := .Path -}}
{{- $Context := .Context -}}
{{- range .Hosts }}
  - host: {{ . }}
    http:
      paths:
{{ include "appsuite.ingress.path" (dict "Path" $Path "Context" $Context) | indent 8 }}
{{- end -}}
{{- end -}}
