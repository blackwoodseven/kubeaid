# Obmondo K8s Agent

The Obmondo K8s Agent (`ghcr.io/obmondo/obmondo-k8s-agent`) runs inside the cluster, pulls cluster metrics from
the Prometheus API and forwards them to the Obmondo API over mTLS. It also tracks the cluster's Kubernetes
version against endoflife.date, sends node-count alerts, and can auto-sync a whitelist of Argo CD applications on
a schedule. This chart is authored in KubeAid (not a vendored upstream wrapper).

See also [`kubeaid-agent`](../kubeaid-agent), the agent `kubeaid-cli` deploys on bootstrapped clusters.

## Why it's in KubeAid

It is how an Obmondo-managed cluster reports its metrics and state to the Obmondo platform, and how routine Argo
CD syncs of approved apps are automated (`argo.cron_sync_interval: 2h` in the rendered config).

## Prerequisites

- `k8s-agent-tls` Secret in the release namespace: the Obmondo mTLS client certificate. Copy `tls.crt`/`tls.key`
  from the existing `obmondo-clientcert` Secret (`monitoring` namespace on most clusters), then seal:

  ```sh
  kubectl get secret obmondo-clientcert -n monitoring --template='{{index .data "tls.crt" | base64decode}}' > tls.crt
  kubectl get secret obmondo-clientcert -n monitoring --template='{{index .data "tls.key" | base64decode}}' > tls.key
  kubectl create secret tls k8s-agent-tls -n obmondo --dry-run=client --key=tls.key --cert=tls.crt -o yaml | \
    kubeseal --controller-namespace system --controller-name sealed-secrets > k8s-agent-tls.yaml
  ```

  The Deployment carries `secret.reloader.stakater.com/reload: k8s-agent-tls`, so a cert rotation restarts the pod.
- `argo-credentials` Secret (name via `ArgoSecret.name`) with `ARGO_USER`/`ARGO_PASSWORD` — or a token key — for
  the Argo CD sync feature.
- Prometheus reachable at `PROMETHEUS_URL` (default `http://prometheus-k8s.monitoring:9090`).

## Key values / KubeAid-specific configuration

| Value | Default | Meaning |
|---|---|---|
| `image.repository` / `image.tag` | `ghcr.io/obmondo/obmondo-k8s-agent` / chart `appVersion` | Agent image. |
| `envVars` | see values.yaml | `API_URL`, `PROMETHEUS_URL`, cert paths, `ENDOFLIFEURL`, `NODE_COUNT_ALERT_INTERVAL`, ... |
| `ArgoSecret` | `argo-credentials` | Secret and keys injected for Argo CD auth (user/password or token). |
| `networkPolicy` | `false` | Render a Calico NetworkPolicy (hard-coded to the `obmondo` namespace): Prometheus scrape in on 8080; DNS, Prometheus, `argocd-server` and 443 egress. |
| `imagePullSecrets` | `[]` | Set if your image registry requires auth. |
| `metrics.serviceMonitor.*` | 30s interval | ServiceMonitor for the agent's own metrics on port 8080. |

The agent's runtime config is rendered by `templates/k8sAgentConfig.yaml` (fetch/alert intervals, Argo CD service
URL `argocd-server.argocd:80`, sync timeout) and the auto-sync whitelist by `templates/whiteListedAppsConfig.yaml`
— one app name per line in `white_listed_apps.yaml`, empty by default so nothing syncs automatically.

## Operational notes

- RBAC: cluster-wide read (`get`/`list`/`watch`) on `networkpolicies` and Argo CD `applications` only, via the
  `network-policy-viewer` ClusterRole.
- Deploy via an Argo CD Application pointing at `argocd-helm-charts/obmondo-k8s-agent` with your override values
  file (namespace `obmondo`, `CreateNamespace=true`).

## Docs links

- Chart source: `templates/` and [values.yaml](./values.yaml) in this directory.
- Obmondo: <https://obmondo.com>
