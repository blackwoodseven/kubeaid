# Filebeat (deprecated)

> **⚠️ Deprecated.** This chart is deprecated and is not recommended for new KubeAid
> installations. Filebeat is the Elastic Beats-era log shipper. KubeAid standardizes log
> collection on the **OpenTelemetry Collector** (with **Fluent Bit** as a lightweight
> alternative), shipping to [OpenObserve](../openobserve/README.md) by default, or to
> [OpenSearch](../opensearch/README.md) where an Apache-2.0 backend is required.
>
> The chart remains in the repository for existing clusters but will not receive further
> updates. See [Monitoring in KubeAid](../../docs/monitoring.md) for the current log
> collection and storage options.

## What this chart does

Filebeat runs as a DaemonSet and ships container and node logs to Elasticsearch- or
OpenSearch-compatible backends. It wraps the upstream
[`elastic/filebeat`](https://helm.elastic.co) chart.

## Migrating off Filebeat

Log collection in KubeAid is handled by an agent running as a DaemonSet on every node, which
tails `/var/log/pods` and ships logs to a backend. Replace Filebeat with one of:

- **OpenTelemetry Collector** — the default agent for logs, metrics, and traces; ingested by
  OpenObserve over `OTLP`. See the
  [OpenObserve Collector reference](../openobserve/charts/openobserve-collector/docs/README.md).
- **Fluent Bit** — a lightweight logs-only shipper for resource-constrained nodes; see the
  [`fluent-bit`](../fluent-bit) chart.

Both feed [OpenObserve](../openobserve/README.md) (default) or
[OpenSearch](../opensearch/README.md).
