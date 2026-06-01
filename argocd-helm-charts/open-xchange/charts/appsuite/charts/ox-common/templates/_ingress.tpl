{{/*
Generates the TLS structure for ingresses. 

Example: 
values.yaml: 
ingress: 
  tls: 
    - secretName: appsuite-tls
      hosts:
        - host: appsuite.open-xchange.com 
        - host: appsuite-stable.open-xchange.com

{{- if .Values.ingress.tls }}
  tls: {{ include "ox-common.ingress.tls" .Values.ingress.tls }}
{{- end }}

*/}}
{{- define "ox-common.ingress.tls" -}}
{{- range . }}
- hosts:
    {{- range .hosts }}
    - {{ .host | quote }}
    {{- end }}
  secretName: {{ .secretName }}
{{- end }}
{{- end -}}

{{/*  
Generates the path prefix for HTTP paths. Uses .ingress.prefix falling back to .global.ingress.prefix. 
Appends a / if the prefix doesn't end in one

{{ include "common.ingress.prefix" ( dict "ingress" .Values.ingress "context" . "global" $) }}
Example values: 
ingress:
  prefix: "appsuite/"

*/}}
{{- define "ox-common.ingress.prefix" -}}
{{- $context := .context -}}
{{- $global := .global -}}
{{- $globalIngressValues := dict -}}
{{- if $global.Values.global -}}
{{- if $global.Values.global.ingress -}}
{{- $globalIngressValues = $global.Values.global.ingress -}}
{{- end -}}
{{- end -}}
{{- $ingress := .ingress -}}
{{- $prefix := $ingress.prefix -}}
{{- if and (not $prefix) $globalIngressValues.prefix -}}
    {{$prefix = $globalIngressValues.prefix }}
{{- end -}}
{{- if $prefix -}}
    {{- if not (hasSuffix "/" $prefix) -}}
{{ printf "%s/" $prefix }}
    {{- else -}}
{{ $prefix }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generates the ingressClassName. Can be either set on an individual ingress object or globally.

Example Values: 

ingress:
  className: myIngressClass

or globally: 

global:
  ingress:
    className: myIngressClass

Usage: 

spec:
  ingressClassName {{ include "ox-common.ingress.className" ( dict "ingress" .Values.ingress "context" . "global" $) }}

*/}}
{{- define "ox-common.ingress.className" -}}
{{- $context := .context -}}
{{- $global := .global -}}
{{- $globalIngressValues := dict -}}
{{- if $global.Values.global -}}
{{- if $global.Values.global.ingress -}}
{{- $globalIngressValues = $global.Values.global.ingress -}}
{{- end -}}
{{- end -}}
{{- $ingress := .ingress -}}
{{- $className := $ingress.className -}}
{{- if and (not $className) $globalIngressValues.className -}}
    {{$className = $globalIngressValues.className }}
{{- end -}}
{{ if $className}}
{{- toString $className -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

{{/*  
Prefixes a given path with the ox-common.ingress.prefix. (See also there). 

{{ include "common.ingress.addPrefixToPath" ( dict "path" "api" "ingress" .Values.ingress "context" . "global" $) }}
Example values: 
ingress:
  prefix: "appsuite/"
  
*/}}
{{- define "ox-common.ingress.addPrefixToPath" -}}
{{- if eq (include "ox-common.ingress.prefix" .) "" -}}
{{ .path }}
{{- else -}}
{{ printf "%s%s" (include "ox-common.ingress.prefix" .) (trimPrefix "/" .path) }}
{{- end -}}
{{- end -}}

{{/*
Generates the appropriate ingress annotations for URL rewrites for a certain controller. 
The controller is determined by looking at the given .ingress.controller falling back to .global.ingress.controller. 
Alternatively you can also specify a .ingress.rewriteAnnotation, or specify a global one, if you're using a different ingress
controller from the supported ones. That template gets executed with the given argument. 

Supported ingress controllers are "nginx" and "traefik"

{{ include "common.ingress.rewriteTo" "targetPath" "/ajax/" "ingress" .Values.ingress "context" . "global" $ }}
*/}}
{{- define "ox-common.ingress.rewriteTo" -}}
{{- $values := .context.Values -}}
{{- $global := .global -}}
{{- $ingress := .ingress -}}
{{- $ingressController := "" -}}
{{- $annotationTemplate := "" -}}
{{- if $global.ingress -}}
{{- $ingressController = $ingress.controller | default $global.ingress.controller | default "nginx" -}}
{{- $annotationTemplate = $ingress.rewriteAnnotationTemplate | default $global.ingress.rewriteAnnotationTemplate | default "" -}}
{{- else -}}
{{- $ingressController = $ingress.controller | default "nginx" -}}
{{- $annotationTemplate = $ingress.rewriteAnnotationTemplate | default "" -}}
{{- end -}}
{{- if eq $annotationTemplate "" -}}
{{- if $ingressController -}}
{{- $annotationTemplate = printf "ox-common.ingress.rewriteTo.%s" $ingressController -}}
{{- end -}}
{{- end -}}
{{ include $annotationTemplate . }}
{{- end -}}

{{/*
Modifies the path so the rewriteTo annotations can work. For some controllers we need to add matches and matching groups. 
This call does that. Works in conjunction with "ox-common.ingress.rewriteTo" 

Supported ingress controllers are "nginx" and "traefik"

{{ include "common.ingress.rewriteTo" "path" "/appsuite/api" "ingress" .Values.ingress "context" . "global" $ }}
*/}}
{{- define "ox-common.ingress.rewriteTo.modifyPath" -}}
{{- $values := .context.Values -}}
{{- $global := .global -}}
{{- $ingress := .ingress -}}
{{- $ingressController := "" -}}
{{- $modificationTemplate := "" -}}
{{- if $global.ingress -}}
{{- $ingressController = $ingress.controller | default $global.ingress.controller | default "nginx" -}}
{{- $modificationTemplate = $ingress.rewriteModificationTemplate | default $global.ingress.rewriteModificationTemplate | default "" -}}
{{- else -}}
{{- $ingressController = $ingress.controller | default "nginx" -}}
{{- $modificationTemplate = $ingress.rewriteModificationTemplate | default "" -}}
{{- end -}}
{{- if eq $modificationTemplate "" -}}
{{- if $ingressController -}}
{{- $modificationTemplate = printf "ox-common.ingress.rewriteTo.%s.modifyPath" $ingressController -}}
{{- end -}}
{{- end -}}
{{ include $modificationTemplate . }}
{{- end -}}

{{/*
Generates the appropriate ingress annotations for sticky traffic. 
The controller is determined by looking at the given .ingress.controller falling back to .global.ingress.controller. 
Alternatively you can also specify a .ingress.rewriteAnnotation, or specify a global one, if you're using a different ingress
controller from the supported ones. That template gets executed with the given argument. 

Supported ingress controllers are "nginx" and "traefik"

{{ include "common.ingress.sticky" "ingress" .Values.ingress "context" . "global" $ }}
*/}}
{{- define "ox-common.ingress.sticky" -}}
{{- $values := .context.Values -}}
{{- $global := .global -}}
{{- $ingress := .ingress -}}
{{- $ingressController := "" -}}
{{- $template := "" -}}
{{- if $global.ingress -}}
{{- $ingressController = $ingress.controller | default $global.ingress.controller | default "nginx" -}}
{{- $template = $ingress.stickyTemplate | default $global.ingress.stickyTemplate | default "" -}}
{{- else -}}
{{- $ingressController = $ingress.controller | default "nginx" -}}
{{- $template = $ingress.stickyTemplate | default "" -}}
{{- end -}}
{{- if eq $template "" -}}
{{- if $ingressController -}}
{{- $template = printf "ox-common.ingress.sticky.%s" $ingressController -}}
{{- end -}}
{{- end -}}
{{ include $template . }}
{{- end -}}


{{- /* NGINX */ -}}
{{- define "ox-common.ingress.rewriteTo.nginx" -}} 
nginx.ingress.kubernetes.io/rewrite-target: {{ .targetPath }}/$2 
{{- end -}}

{{- define "ox-common.ingress.rewriteTo.nginx.modifyPath" -}}
{{ printf "%s(/|$)(.*)" .path }}
{{- end -}}

{{- define "ox-common.ingress.sticky.nginx" -}}
nginx.ingress.kubernetes.io/affinity: "cookie"
{{ if .cookieName -}}
nginx.ingress.kubernetes.io/session-cookie-name: {{ .cookieName }}
{{ else -}}
nginx.ingress.kubernetes.io/session-cookie-name: {{ include "ox-common.names.fullname" .context | replace "-" "" }}
{{ end -}}
nginx.ingress.kubernetes.io/session-cookie-change-on-failure: "true"
nginx.ingress.kubernetes.io/affinity-mode: "persistent"
nginx.ingress.kubernetes.io/session-cookie-path: {{ .path }}
{{- end -}}


{{- /* Traefik */ -}}
{{- define "ox-common.ingress.rewriteTo.traefik" -}}
traefik.ingress.kubernetes.io/rewrite-target: {{ .targetPath }}
{{- end -}}

{{- define "ox-common.ingress.rewriteTo.traefik.modifyPath" -}}
{{ .path }}
{{- end -}}

{{- define "ox-common.ingress.sticky.traefik" -}}
traefik.ingress.kubernetes.io/affinity: "true"
{{- end -}}


{{/* 
Generates default ingress manifests. The generated manifests are governed by three things: 
1 The path mapping

In the chart using the ox-common library chart, define a template that generates yaml with a paths object 
containing a list of objects defining the paths that need to be mapped: 

{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /api
{{- end -}}

This will create an ingress resource that forwards requests to /api to the service with the name "ox-common.names.fullname" at the http port

You can override the service name and port: 

{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /api
    targetService: {{ include "ox-common.names.fullname" . }}-api
    targetPort: 
      number: 8009
{{- end -}}

or, using the name: 

{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /api
    targetService: {{ include "ox-common.names.fullname" . }}-api
    targetPort: 
      name: grpc
{{- end -}}


If you need an URL rewrite, you can also include a targetPath: 

{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /api
    targetPath: /ajax
    targetService: {{ include "ox-common.names.fullname" . }}-api
    targetPort: 
      number: 8009
{{- end -}}

If you need session stickiness you can add a switch for that as well: 

{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /api
    targetPath: /ajax
    targetService: {{ include "ox-common.names.fullname" . }}-api
    targetPort: 
      number: 8009
    sticky: true
{{- end -}}

For nginx this will use a cookie name generated from the fullname. If you want to specify the cookie name, you can: 

{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /api
    targetPath: /ajax
    targetService: {{ include "ox-common.names.fullname" . }}-api
    targetPort: 
      number: 8009
    sticky: true
    stickyCookie: "MYJSESSIONID"
{{- end -}}

You may opt out of the automatic prefix handling for a path by setting `ignorePrefix`. That way 
the prefix (see further down) will not be prepended to this path

```
{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /.well-known
    ignorePrefix: true
{{- end -}}
```


You can list as many paths as needed. 

Finally: You need to reference that pathMappings template in you values as ingress.pathMappings

Example: 
values.yaml: 
ingress:
  pathMappings: "mychart.ingressPathMappings"

_ingress.tpl: 
{{- define "mychart.ingressPathMappings" -}}
paths:
  - path: /complexity-api
    targetPath: /complexity/api
  - path: /complexity-cache
  - path: /complexity-session
    sticky: true
    targetPath: /complexity/session
{{- end -}}

2 global chart values

Global chart variables govern other aspects of the ingress resources. Most of these can be overridden in the specific local chart values. 
It is could practice to specify the ones mentioned here globally, to not repeat them for subcharts when building a deployment. 

You can specify hosts for incoming requests: 

global:
  ingress: 
    hosts:
      - appsuite.open-xchange.com 
      - appsuite-stable.open-xchange.com

You can specify a prefix for the entire installation:

global:
  ingress: 
    prefix: appsuite/
    hosts:
      - appsuite.open-xchange.com 
      - appsuite-stable.open-xchange.com

All of the paths from the path mapping will be moved under /appsuite/ and rewritten. 

You can globally specify TLS settings: 

global:
  ingress: 
    tls: 
      - secretName: appsuite-tls
        hosts:
          - appsuite.open-xchange.com 
          - appsuite-stable.open-xchange.com

This way you can manage certificates in an umbrella chart for multiple services. 

You can specify global annotations that are added to every ingress: 
global:
  ingress: 
    annotations:
      ingress.open-xchange.com/superspeed: true 

You can specify an ingressClassName that is specified for every ingress:

global:
  ingress:
    className: myIngressClass


3 local chart values

Many of the global values can also be set locally and either merged with the global values or override them. 

The prefix can be overwritten in a chart: 

ingress:
  prefix: "/appsuite/v8"

The global ingressClassName can also be overridden: 

ingress:
  className: mySpecificIngressClass

Hosts and TLS sections are merged together with the global sections. So if you want to expose
a service under an additional hostname, you can add the relevant section in the local values: 

ingress:
  hosts: 
    - additional.open-xchange.com
  tls:
    secretName: additional-tls
    hosts:
      - additional.open-xchange.com

This will create a separate ingress resource for each path with special annotations (for stickyness and rewrites) and collect
all unmodified paths in a general ingress. Though, as soon as a prefix is in play, we need a separate ingress resource for
each path. Exposing path mappings in a template as described above also works together with other library charts generating
istio configuration.

Example Usage: 
{{- if .Values.ingress.enabled -}}
{{ include "ox-common.ingress.defaultIngress" (dict "ingress" .Values.ingress "context" . "global" $) }}
{{- end }}
 */}}
{{- define "ox-common.ingress.defaultIngress" -}}
{{- $context := .context -}}
{{- $global := .global -}}
{{- $globalIngressValues := dict -}}
{{- if $global.Values.global -}}
{{- if $global.Values.global.ingress -}}
{{- $globalIngressValues = $global.Values.global.ingress -}}
{{- end -}}
{{- end -}}
{{- $ingress := .ingress -}}
{{- $hosts := $ingress.hosts -}}
{{- if $ingress.extraHosts -}}
{{- $hosts = concat $hosts $ingress.extraHosts -}}
{{- end -}}
{{- if $globalIngressValues.hosts -}}
{{- $hosts = concat $hosts $globalIngressValues.hosts -}}
{{- end -}}
{{ $tls := $ingress.tls | default list -}}
{{- if $globalIngressValues.tls }}
{{- $tls = concat $tls $globalIngressValues.tls -}}
{{- end }}
{{- $paths := (include $ingress.pathMappings $context | fromYaml).paths -}}
{{- /* Firstly we'll sort the paths in paths we can map as is and those that need special annotations of some kind */ -}}
{{- $verbatimPaths := list -}}
{{- $annotatedPaths := list -}}
{{- range $paths -}}
  {{- /* If either the targetPath is set or sticky is set or if a prefix is set AND this path does not ignore the prefix, then this path needs annotations */ -}}
  {{- if or .targetPath .sticky (and (not .ignorePrefix) (ne "" (include "ox-common.ingress.prefix" (dict "ingress" $ingress "context" $context "global" $global )))) -}}
    {{- $annotatedPaths = append $annotatedPaths . -}}
  {{- else -}}
    {{- $verbatimPaths = append $verbatimPaths . -}}
  {{- end -}}
{{- end -}}
{{- $standardAnnotations := $ingress.annotations | default dict -}}
{{- if $globalIngressValues.annotations -}}
{{- $standardAnnotations = merge $standardAnnotations $globalIngressValues.annotations -}}
{{- end -}}
{{- if ne (len $verbatimPaths) 0 }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  {{ if $ingress.name }}
  name: {{ include "ox-common.names.fullname" $context }}-{{ $ingress.name }}
  {{ else }}
  name: {{ include "ox-common.names.fullname" $context }}
  {{ end }}
  labels:
    {{- include "ox-common.labels.standard" $context | nindent 4 }}
  {{ if ne 0 (len $standardAnnotations) }}
  annotations: {{ toYaml $standardAnnotations | nindent 4 }}
  {{ end }}
spec:
  {{ if ne 0 (len $tls) -}}
  tls: {{ include "ox-common.ingress.tls" $tls | nindent 4 }}
  {{ end }}
  {{- if ne "" (include "ox-common.ingress.className" (dict "ingress" $ingress "context" $context "global" $global))}}
  ingressClassName: {{ include "ox-common.ingress.className" (dict "ingress" $ingress "context" $context "global" $global) }}
  {{- end }}
  rules:
    {{- range $hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range $verbatimPaths }}
          {{ if not .targetPath -}}
          - path: {{ .path }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ .targetService | default (include "ox-common.names.fullname" $context ) }}
                {{ if .targetPort }}
                port: {{ toYaml .targetPort | nindent 18}}
                {{- else -}}
                port: 
                  name: http
                {{- end -}}
          {{- end }}
          {{- end }}
    {{- end }}
{{- end -}}
{{- $counter := 0 -}}
{{ range $annotatedPaths }}
---
{{ $counter = (add $counter 1) }}
{{- $targetPath := .path -}}
{{- if not .ignorePrefix -}}
{{- $targetPath = include "ox-common.ingress.addPrefixToPath" (dict "path" $targetPath "ingress" $ingress "context" $context "global" $global) -}}
{{- end -}}
{{- if .targetPath -}}
{{- $targetPath = include "ox-common.ingress.rewriteTo.modifyPath" (dict "path" $targetPath "ingress" $ingress "context" $context "global" $global ) -}}
{{- end -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  {{ if $ingress.name }}
  name: {{ include "ox-common.names.fullname" $context }}-{{ $ingress.name }}-{{ $counter }}
  {{ else }}
  name: {{ include "ox-common.names.fullname" $context }}-{{ $counter }}
  {{ end }}
  labels:
    {{- include "ox-common.labels.standard" $context | nindent 4 }}

  annotations: 
  {{- if ne 0 (len $standardAnnotations) -}}
  {{ toYaml $standardAnnotations | nindent 4 }}
  {{- end -}}
  {{- if .targetPath -}}
  {{ include "ox-common.ingress.rewriteTo" (dict "targetPath" .targetPath "ingress" $ingress "context" $context "global" $) | nindent 4 }}
  {{- else if (and (not .ignorePrefix) (ne "" (include "ox-common.ingress.prefix" (dict "ingress" $ingress "context" $context "global" $global)))) -}}
  {{ include "ox-common.ingress.rewriteTo" (dict "targetPath" .path "ingress" $ingress "context" $context "global" $) | nindent 4 }}
  {{ end -}}
  {{- if .sticky -}}
  {{ include "ox-common.ingress.sticky" (dict "cookieName" .stickyCookie "path" .path "ingress" $ingress "context" $context "global"  $) | nindent 4 }}
  {{- end }}
spec:
  {{ if ne 0 (len $tls) -}}
  tls: {{ include "ox-common.ingress.tls" $tls | nindent 4 }}
  {{ end }}
  {{ if ne "" (include "ox-common.ingress.className" (dict "ingress" $ingress "context" $context "global" $global))}}
  ingressClassName: {{ include "ox-common.ingress.className" (dict "ingress" $ingress "context" $context "global" $global) }}
  {{ end }}
  rules:
    {{- $pathSpec := . -}}
    {{- range $hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          - path: {{ $targetPath }}
            pathType: {{ $pathSpec.pathType | default "Prefix" }}
            backend:
              service:
                name: {{ $pathSpec.targetService | default (include "ox-common.names.fullname" $context ) }}
                {{ if $pathSpec.targetPort -}}
                port: {{ toYaml $pathSpec.targetPort | nindent 18}}
                {{- else -}}
                port: 
                  name: http
                {{- end -}}
    {{- end }}
{{- end -}}
{{- end -}}

{{/*
In case your projects spans mutliple services with their own mappings, you can use this helper to create the 
Ingress resources. Pass in a dictionary with a key for each of the mappings you need to create ingresses for

values.yaml: 
```
ingress:

  api:
    pathMappings: "complexity.ingress.apiPathMappings"
    enabled: true
    annotations: {}
    hosts:
      - host: chart-example.local
    tls: []
    
  files:
    pathMappings: "complexity.ingress.filesPathMappings"
    enabled: true
    annotations: {}
    hosts:
      - host: chart-example.local
    tls: []
    
  assets:
    pathMappings: "complexity.ingress.assetsPathMappings"
    enabled: true
    annotations: {}
    hosts:
      - host: chart-example.local
    tls: []
```

_ingress.tpl
```
{{- define "complexity.ingress.apiPathMappings" -}}
paths:
  - path: /api
    targetService: {{ include "ox-common.names.fullname" . }}-api
  - path: /ajax
    targetService: {{ include "ox-common.names.fullname" . }}-api
{{- end -}}

{{- define "complexity.ingress.filesPathMappings" -}}
paths:
  - path: /files
    targetService: {{ include "ox-common.names.fullname" . }}-files
{{- end -}}

{{- define "complexity.ingress.assetsPathMappings" -}}
paths:
  - path: /assets
    targetService: {{ include "ox-common.names.fullname" . }}-assets
{{- end -}}
```

ingress.yaml: 
```
{{ include "ox-common.ingress.multipleIngresses" (dict "ingresses" .Values.ingress "context" . "global" $ )}}
```

This will iterate all three dicts (api, files and assets) and set up ingresses according to their settings, the global settings
and the path mappings. You can also pass in an "allKey". Settings below that key are merged with the settings of the individual
service keys: 
values.yaml: 
```
ingress:
  _all: 
    enabled: true
    annotations: {}
    hosts:
      - host: chart-example.local
    tls: []

  api:
    pathMappings: "complexity.ingress.apiPathMappings"
    
  files:
    pathMappings: "complexity.ingress.filesPathMappings"
    
  assets:
    pathMappings: "complexity.ingress.assetsPathMappings"
```

ingress.yaml: 
```
{{ include "ox-common.ingress.multipleIngresses" (dict "ingresses" .Values.ingress "context" . "global" $ "allKey" "_all")}}
```
*/}}
{{- define "ox-common.ingress.multipleIngresses" -}}
{{- $context := .context -}}
{{- $global := .global -}}
{{- $allKey := .allKey -}}
{{- $ingresses := .ingresses -}}
{{- $overallSettings := dict -}}
{{- if $allKey -}}
{{- $overallSettings = get $ingresses $allKey -}}
{{- end -}}
{{ range $key, $ingress := $ingresses }}
{{- if $allKey -}}
{{- if ne $allKey $key -}}
{{- $ingress := deepCopy $overallSettings | merge $ingress -}}
{{- if $ingress.enabled -}}
{{- if not $ingress.name -}}
{{ $_ := set $ingress "name" $key }}
{{- end -}}
{{ include "ox-common.ingress.defaultIngress" (dict "ingress" $ingress "context" $context "global" $global) }}
---
{{- end -}}
{{- end -}}
{{- else -}}
{{- if $ingress.enabled -}}
{{- if not $ingress.name -}}
{{ $_ := set $ingress "name" $key }}
{{- end -}}
{{ include "ox-common.ingress.defaultIngress" (dict "ingress" $ingress "context" $context "global" $global) }}
---
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
