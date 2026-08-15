# Prometheus Adapter

Wrapper around the upstream [prometheus-adapter](https://github.com/kubernetes-sigs/prometheus-adapter) Helm
chart (v5.3.0). Implements the Kubernetes `custom.metrics.k8s.io` and `external.metrics.k8s.io` APIs by
translating PromQL queries against Prometheus into metrics the API server (and HPA) can consume.

## Why it's in KubeAid

Enables Horizontal Pod Autoscaling on metrics other than CPU/memory - request rate, queue depth, or any
other Prometheus series - by exposing them through the custom metrics API. See the autoscaling section of
[Prometheus Configuration](../../docs/kubeaid/prometheus-configuration.md), which documents adding rules via
`prometheus_adapter_additional_rules` in the cluster's Jsonnet config and enabling
`enable_custom_metrics_apiservice`.

## Prerequisites

- `kube-prometheus` (Prometheus) running in-cluster - this chart points at it directly.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `prometheus-adapter.prometheus.url` | Prometheus service the adapter queries | `kube-prometheus-stack-prometheus.monitoring.svc` |

Custom metric rules themselves are not set in this chart's `values.yaml` - they are generated from the
cluster's `kube-prometheus` Jsonnet config (`prometheus_adapter_additional_rules`) and applied alongside the
rest of the `kube-prometheus` build.

## Docs links

- [Prometheus Adapter docs](https://github.com/kubernetes-sigs/prometheus-adapter)
- [Prometheus Configuration / custom metrics & autoscaling](../../docs/kubeaid/prometheus-configuration.md)
- [Pod Autoscaling Guide](../../docs/operations/monitoring/pod-autoscaling.md)
