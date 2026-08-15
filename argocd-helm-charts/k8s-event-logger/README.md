# k8s-event-logger

Wrapper around the upstream [k8s-event-logger](https://github.com/deliveryhero/helm-charts/tree/master/stable/k8s-event-logger)
Helm chart (v1.1.8). Watches the Kubernetes API for Events and writes them to its own stdout as structured
log lines, so they can be picked up by whichever log stack the cluster runs.

## Why it's in KubeAid

Kubernetes Events (`kubectl get events`) are ephemeral and namespaced by default - once they expire from
etcd they're gone. This chart turns them into durable, centrally-searchable log lines by shipping them
through the cluster's log pipeline (Graylog, OpenObserve, or OpenSearch) alongside application logs.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `networkpolicies` | Enable this chart's NetworkPolicy resources | `false` |
| `k8s-event-logger.env.KUBERNETES_API_URL` | API server URL the logger watches | `https://kubernetes.default.svc` |

All other configuration is forwarded to the upstream chart under the `k8s-event-logger` key; see the
[vendored chart README](./charts/k8s-event-logger/README.md).

## Operational notes

- When `networkpolicies: true`, a Calico `NetworkPolicy` (`templates/netpol-k8s-event-logger.yaml`) allows
  egress to nodes labelled `kubernetes.io/role == 'master'` on port 443, so the logger can reach the
  apiserver even when a default-deny egress policy is in place.

## Docs links

- Upstream chart README: [`charts/k8s-event-logger/README.md`](./charts/k8s-event-logger/README.md)
- [Monitoring / log stack comparison](../../docs/monitoring.md)
