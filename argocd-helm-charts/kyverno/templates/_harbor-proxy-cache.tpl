{{/*
  CEL expression that maps one image reference to its Harbor proxy-cache
  equivalent. Call with a dict:
    img:       CEL variable holding the image string, e.g. "c.image"
    registry:  Harbor host
    dockerHub: Harbor project that proxies Docker Hub
    ghcr:      Harbor project that proxies ghcr.io ("" disables the branch)
    k8s:       Harbor project that proxies registry.k8s.io ("" disables the branch)

  Order matters: an image already on our Harbor is left alone; explicit Docker
  Hub hosts are stripped; ghcr.io and registry.k8s.io are rewritten only when a
  project is configured; the last two branches catch the implicit Docker Hub
  forms "org/name:tag" and "name:tag". Official images get "library/" so Harbor
  can resolve them. substring(N) drops the host prefix; N is its length.
*/}}
{{- define "kubeaid.kyverno.harborRewrite" -}}
{{- $i := .img -}}
{{ $i }}.startsWith("{{ .registry }}/") ? {{ $i }}
: {{ $i }}.startsWith("index.docker.io/") ? "{{ .registry }}/{{ .dockerHub }}/" + ({{ $i }}.substring(16).contains("/") ? {{ $i }}.substring(16) : "library/" + {{ $i }}.substring(16))
: {{ $i }}.startsWith("registry-1.docker.io/") ? "{{ .registry }}/{{ .dockerHub }}/" + ({{ $i }}.substring(21).contains("/") ? {{ $i }}.substring(21) : "library/" + {{ $i }}.substring(21))
: {{ $i }}.startsWith("docker.io/") ? "{{ .registry }}/{{ .dockerHub }}/" + ({{ $i }}.substring(10).contains("/") ? {{ $i }}.substring(10) : "library/" + {{ $i }}.substring(10))
{{- if .ghcr }}
: {{ $i }}.startsWith("ghcr.io/") ? "{{ .registry }}/{{ .ghcr }}/" + {{ $i }}.substring(8)
{{- end }}
{{- if .k8s }}
: {{ $i }}.startsWith("registry.k8s.io/") ? "{{ .registry }}/{{ .k8s }}/" + {{ $i }}.substring(16)
{{- end }}
: {{ $i }}.matches("^[^/.:]+/.+$") ? "{{ .registry }}/{{ .dockerHub }}/" + {{ $i }}
: {{ $i }}.matches("^[^/]+$") ? "{{ .registry }}/{{ .dockerHub }}/library/" + {{ $i }}
: {{ $i }}
{{- end }}
