# OpenSearch Dashboards

Wrapper around the upstream [opensearch-dashboards](https://opensearch-project.github.io/helm-charts/) Helm
chart (v3.8.0). Provides the web UI for search, visualization, and dashboards on top of an OpenSearch
cluster - KubeAid's equivalent to Kibana (not packaged in KubeAid).

## Why it's in KubeAid

Pairs with [`opensearch`](../opensearch) as a standalone, ELK-style log stack: an alternative to Graylog for
clusters that want direct log search and visualization without a Graylog management layer. See the log-stack
comparison in [Monitoring](../../docs/monitoring.md).

## Prerequisites

- An [`opensearch`](../opensearch) cluster to point Dashboards at.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `networkpolicies` | Enable NetworkPolicy resources for this release | `false` |

All other configuration is forwarded to the upstream chart under the `opensearch-dashboards` key; see the
[vendored chart README](./charts/opensearch-dashboards/README.md) for the full parameter list.

## Docs links

- [OpenSearch Dashboards docs](https://opensearch.org/docs/latest/dashboards/)
- Upstream chart README: [`charts/opensearch-dashboards/README.md`](./charts/opensearch-dashboards/README.md)
- [Monitoring / log stack comparison](../../docs/monitoring.md)
- Related: [`opensearch`](../opensearch), [`opensearch-operator`](../opensearch-operator), [`graylog`](../graylog)
