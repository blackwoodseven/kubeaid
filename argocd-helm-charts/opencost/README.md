# Opencost

Opencost is an engine which can give us a real time info to see, how much money is spend on the k8s resources
so far it supports namespace, deployment, controller, label, pod, and node.

https://www.opencost.io/

## Why it's in KubeAid

Cost visibility for workloads running on a KubeAid-managed cluster, without depending on a paid SaaS. It reads
usage from Prometheus and turns it into per-namespace/deployment/pod cost, so cluster owners can see where
spend is going on their own infra.

https://github.com/opencost/opencost/issues/2022 is raised for getting the same info for volume snapshot

## Key values

Chart wraps the upstream `opencost` subchart (`argocd-helm-charts/opencost/values.yaml`):

- `opencost.opencost.prometheus.external.enabled: true`, pointed at `http://prometheus-k8s.monitoring:9090` —
  opencost reads cost data from the cluster's existing Prometheus rather than running its own.
- `opencost.opencost.metrics.serviceMonitor.enabled: true` — opencost's own metrics get scraped too.
- `opencost.opencost.ui.enabled: true` with `ui.ingress.enabled: true` — the bare-minimum web UI is exposed.

## API

https://www.opencost.io/docs/api

## CLI

You can access cli to get the same info

https://github.com/kubecost/kubectl-cost#installation

## WebUI

kubecost is the enterprise version, which has a decent UI

https://www.kubecost.com/

opencost is an opensource version of kubecost, which has a bare minimum webui for now.
