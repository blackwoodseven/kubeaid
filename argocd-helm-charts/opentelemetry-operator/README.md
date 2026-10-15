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
| `opentelemetry-operator.manager.featureGatesMap.operator.networkpolicy` | Keep the operator from creating a NetworkPolicy for itself; on Cilium it blocks the operator's own API access | `false` |
| `opentelemetry-operator.manager.collectorImage.repository` | Default collector image the operator injects for `OpenTelemetryCollector` CRs | `otel/opentelemetry-collector-k8s` |
| `opentelemetry-collector.image.repository` | Image for this chart's own collector release | `otel/opentelemetry-collector-k8s` |
| `opentelemetry-collector.mode` | Deployment mode for this chart's own collector | `daemonset` |

## Upgrading from KubeAid 33.0.3

KubeAid 33.0.3 ships operator 0.159.0, which creates a NetworkPolicy named
`opentelemetry-operator` in the operator's namespace. On Cilium that policy blocks the
operator's access to the API server, and the operator crash-loops (`dial tcp
10.96.0.1:443: i/o timeout`, then "OpenTelemetryCollector CRDs are not present").
Turning the feature off does not remove the policy, so after syncing this chart, delete
it once:

```bash
kubectl -n <operator-namespace> delete networkpolicy opentelemetry-operator
```

If the rollout still has an operator pod from the old ReplicaSet (feature on), delete
that ReplicaSet first, or that pod can create the policy again.

## Docs links

- [OpenTelemetry Operator docs](https://github.com/open-telemetry/opentelemetry-operator)
- [OpenObserve Collector reference](../openobserve/charts/openobserve-collector/docs/README.md)
- Related: [`openobserve`](../openobserve)
