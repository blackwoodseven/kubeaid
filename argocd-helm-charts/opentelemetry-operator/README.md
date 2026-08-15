# OpenTelemetry Operator

Wrapper around the upstream `opentelemetry-operator` (v0.120.2) and `opentelemetry-collector` (v0.169.0)
Helm charts. Installs the operator and CRDs (`OpenTelemetryCollector`, `Instrumentation`) that manage
OpenTelemetry Collector deployments and language auto-instrumentation declaratively.

## Why it's in KubeAid

[`openobserve`](../openobserve)'s log/metrics/trace pipeline (the `openobserve-collector` sub-chart) is built
entirely on these CRDs: its agent DaemonSet and gateway StatefulSet are both `OpenTelemetryCollector`
resources (`opentelemetry.io/v1beta1`), and its per-language auto-instrumentation
(`instrumentation-go.yaml`, `-java.yaml`, `-python.yaml`, `-nodejs.yaml`, `-dotnet.yaml`) are `Instrumentation`
resources (`opentelemetry.io/v1alpha1`). This operator must be installed before `openobserve-collector` can
reconcile any of them.

## Prerequisites

- Deploy this chart before [`openobserve`](../openobserve) / `openobserve-collector` - the OpenObserve docs
  call this out explicitly.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `opentelemetry-operator.manager.collectorImage.repository` | Default collector image the operator injects for `OpenTelemetryCollector` CRs | `otel/opentelemetry-collector-k8s` |
| `opentelemetry-collector.image.repository` | Image for this chart's own collector release | `otel/opentelemetry-collector-k8s` |
| `opentelemetry-collector.mode` | Deployment mode for this chart's own collector | `daemonset` |

## Docs links

- [OpenTelemetry Operator docs](https://github.com/open-telemetry/opentelemetry-operator)
- [OpenObserve Collector reference](../openobserve/charts/openobserve-collector/docs/README.md)
- Related: [`openobserve`](../openobserve)
