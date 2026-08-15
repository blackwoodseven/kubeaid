# Argo CD Image Updater

[Argo CD Image Updater](https://argocd-image-updater.readthedocs.io/) watches container registries for new image
tags and automatically updates the images of workloads managed by Argo CD Applications, based on annotations on
those Applications.

## Why it's in KubeAid

On a GitOps platform every change must flow through Git — manually bumping image tags in values files for each
release gets old fast. Image Updater automates that step for the [`argo-cd`](../argo-cd) engine: it detects new
tags matching your update strategy and (with the Git write-back method) commits the change to your repo, so the
cluster state and Git history stay in agreement.

Upstream chart: [`argocd-image-updater`](https://github.com/argoproj/argo-helm/tree/main/charts/argocd-image-updater)
from argo-helm.

## Key values / KubeAid-specific configuration

This wrapper is a pure version pin: `values.yaml` is empty and there are no extra templates, so upstream defaults
apply unchanged. All configuration goes in your kubeaid-config values file for the app, nested under the
`argocd-image-updater:` key, e.g.:

```yaml
argocd-image-updater:
  config:
    git.user: kubeaid-bot
    git.email: bot@example.com
    registries:            # non-default registries / credentials
      - name: harbor
        api_url: https://harbor.example.com
        prefix: harbor.example.com
```

Useful upstream knobs: `config.registries` (registry list and credentials), `config.git.*` (commit author,
message template, signing), `authScripts` (helper scripts for ECR/ACR auth), and `metrics` for Prometheus
scraping. Registry or Git credentials referenced from the config should be created as SealedSecrets in your
kubeaid-config repo, like every other secret on a KubeAid cluster.

Which Applications get updated is controlled by annotations on the Application resources themselves
(`argocd-image-updater.argoproj.io/image-list` etc.), not by this chart's values — see the upstream docs.

## Docs links

- Upstream docs: <https://argocd-image-updater.readthedocs.io/>
- Upstream chart: <https://github.com/argoproj/argo-helm/tree/main/charts/argocd-image-updater>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
