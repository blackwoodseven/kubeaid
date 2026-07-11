# loki-stack (deprecated)

> **⚠️ Deprecated.** This chart is deprecated and is not one of KubeAid's documented log
> monitoring options. KubeAid standardizes logs and traces on the **OpenTelemetry Collector →
> [OpenObserve](../openobserve/README.md)** path by default, with
> [Graylog](../graylog/README.md) and [OpenSearch + Kibana](../opensearch/README.md) as
> supported alternatives.
>
> The chart remains in the repository for existing clusters but will not receive further
> updates. See [Monitoring in KubeAid](../../docs/monitoring.md) for the current options.

## What this chart does

`loki-stack` wraps the upstream
[`grafana/loki-stack`](https://grafana.github.io/helm-charts) chart (Loki plus a log shipper)
for centralized log storage and querying via Grafana.

## Migrating off loki-stack

Point your log collector (OpenTelemetry Collector or Fluent Bit) at
[OpenObserve](../openobserve/README.md) instead. OpenObserve stores logs, metrics, and traces
in a single backend on object storage and integrates with `kube-prometheus`; see
[Monitoring in KubeAid](../../docs/monitoring.md).
