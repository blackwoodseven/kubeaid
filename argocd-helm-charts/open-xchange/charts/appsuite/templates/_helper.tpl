{{/*
Defines the gateway name
*/}}
{{- define "appsuite.ingressGateway" -}}
{{- if not (((.Values).istio).ingressGateway).name -}}
{{- printf "%s-%s" (include "ox-common.names.fullname" .) "gateway" | quote }}
{{- else -}}
{{- .Values.istio.ingressGateway.name | quote }}
{{- end -}}
{{- end -}}

{{/*
Return the TLS secret name
*/}}
{{- define "appsuite.secretTLSName" -}}
{{- if ((((.Values).istio).ingressGateway).tls).existingSecret -}}
{{- printf "%s" .Values.istio.ingressGateway.tls.existingSecret | quote -}}
{{- else -}}
{{- printf "%s-%s" (include "ox-common.names.fullname" .) "gateway-tls-secret" | quote -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created for TLS
*/}}
{{- define "appsuite.createTLSSecret" -}}
{{- if and (((((.Values).istio).ingressGateway).tls).enabled) (not ((((.Values).istio).ingressGateway).tls).existingSecret) }}
{{- true -}}
{{- end -}}
{{- end -}}

{{/*
Merges a list with the values of a map to provide an alternative to the list style value that can use map style inheritance.

Usage:
{{- $hosts := (include "appsuite.mergeListWithMap" (dict "list" .Values.istio.ingressGateway.hosts "map" .Values.istio.ingressGateway.overridableHosts) | fromYaml) -}}
*/}}
{{- define "appsuite.mergeListWithMap" -}}
{{- $list := .list -}}
{{- $map := .map -}}
{{- $result := list -}}
{{- range $list -}}
{{-   $result = append $result . -}}
{{- end -}}
{{- range $key, $value := $map -}}
{{-   if $value -}}
{{-     $result = append $result $value -}}
{{-   end -}}
{{- end -}}
{{- (dict "Result" $result) | toYaml -}}
{{- end -}}

{{/*
*
* include "appsuite.segmentedRoutingRedirect" (dict "LocalSite" .Values.istio.segmentedRouting.localSite "Context" . "AppRoot" (include "ox-common.appsuite.appRoot" . ) "Sites" .Values.istio.segmentedRouting.sites "Paths" .Values.istio.segmentedRouting.appsuitePaths)
*
*/}}
{{- define "appsuite.segmentedRoutingRedirect" -}}
{{- $localSite := .LocalSite -}}
{{- $context := .Context -}}
{{- $appRoot := .AppRoot -}}
{{- $paths := .Paths -}}
{{- $port := .Port -}}
{{- range .Sites -}}
{{- $name := .name -}}
{{- if ne $localSite .name }}
- name: "{{ $name | lower }}-segmented-routing-redirect"
  match:
{{- range $paths }}
    - uri:
        prefix: {{ . | replace "%%APP_ROOT%%" $appRoot | quote }}
      headers:
        x-ox-segment: 
          exact: {{ $name | quote }}
{{- end }}
  route:
    - destination:
        host: {{ $name | lower }}.{{ include "ox-common.names.fullname" $context }}.svc.cluster.local
        port:
          number: {{ $port | default 443 }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Creates the destination host for a given route.

The Helm release name is added if the route contains the 'addReleaseName' flag (default: true).
*/}}
{{- define "appsuite.destinationHostForRoute" -}}
{{- $route := .Route -}}
{{- $context := .Context -}}
{{- $result := "" -}}
{{- $placeholder := "%s.%s.svc.cluster.local" -}}
{{- $addReleaseName := true -}}
{{- if not ($route.addReleaseName | quote | empty) -}}
{{-   $addReleaseName = $route.addReleaseName -}}
{{- end -}}
{{- if $route.destinationHostFqdn -}}
{{-   $result = $route.destinationHostFqdn }}
{{- else if eq $addReleaseName true -}}
{{-   $placeholder := "%s-%s.%s.svc.cluster.local" -}}
{{-   $result = printf $placeholder $context.Release.Name $route.destinationHost $context.Release.Namespace }}
{{- else -}}
{{-   $placeholder := "%s.%s.svc.cluster.local" -}}
{{-   $result = printf $placeholder $route.destinationHost $context.Release.Namespace }}
{{- end -}}
{{ $result | quote }}
{{- end -}}

{{/*
Gets the fullname from a given component.
*/}}
{{- define "appsuite.fullnameFromComponent" -}}
{{- $context := .Context -}}
{{- $component := .Component -}}
{{- $componentValues := index $context.Values $component -}}
{{- $componentChart := index $context.Subcharts $component "Chart" -}}
{{- $componentRelease := index $context.Subcharts $component "Release" -}}
{{ include "ox-common.names.fullname" (dict "Values" $componentValues "Chart" $componentChart "Release" $componentRelease) }}
{{- end -}}