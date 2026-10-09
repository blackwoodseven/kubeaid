{{/*
ArgoCD sync-wave annotations. The chart is synced as one Application, so ordering between
Provider packages (whose CRDs do not exist before the Provider is Installed and Healthy) and the
resources using those CRDs is expressed with sync waves. Waves 1 and 2 also skip ArgoCD's dry run
for kinds whose CRD is not on the cluster yet.
*/}}
{{- define "crossplane-provider.wave0" -}}
argocd.argoproj.io/sync-wave: "0"
{{- end }}

{{- define "crossplane-provider.wave1" -}}
argocd.argoproj.io/sync-wave: "1"
argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
{{- end }}

{{- define "crossplane-provider.wave2" -}}
argocd.argoproj.io/sync-wave: "2"
argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
{{- end }}
