# Cerebro

[Cerebro](https://github.com/lmenezes/cerebro) is an open-source web admin tool for Elasticsearch-compatible
clusters (including OpenSearch): node/shard overview, index management, REST console and cluster settings from a
browser instead of raw `curl` against the API.

This is a KubeAid wrapper around the upstream
[wiremind cerebro chart](https://github.com/wiremind/wiremind-helm-charts/tree/main/charts/cerebro) (version 2.3.0).

## Why it's in KubeAid

Gives operators a UI for inspecting and administering the OpenSearch cluster that backs the logging stack
(Graylog/OpenSearch), without port-forwarding to the OpenSearch API and hand-crafting requests.

## Key values / KubeAid-specific configuration

All upstream chart values go under the `cerebro:` key. The wrapper itself sets:

| Value | Default | Meaning |
|---|---|---|
| `cerebro.revisionHistoryLimit` | `0` | Keep no old ReplicaSets around. |
| `networkpolicies` | `false` | Render the Calico `NetworkPolicy` in `templates/netpol-cerebro.yaml`. |

The network policy is written for a specific layout: it is hard-coded to the `graylog` namespace, allows ingress to
Cerebro's port 9000 from `100.0.0.0/8` (the Traefik/pod network), and egress only to pods labelled
`app.kubernetes.io/name: opensearch` on port 9200. Review it before enabling on a differently-shaped cluster.

Cerebro's own settings (target cluster URLs, auth, etc.) are configured through the upstream chart's values — see
its [values.yaml](https://artifacthub.io/packages/helm/wiremind/cerebro).

## Docs links

- Upstream chart: <https://artifacthub.io/packages/helm/wiremind/cerebro>
- Cerebro project: <https://github.com/lmenezes/cerebro>
