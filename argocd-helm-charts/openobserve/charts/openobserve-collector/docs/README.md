# OpenObserve Collector — Data Collection Reference

## Role in KubeAid monitoring

The OpenObserve Collector is the **OpenTelemetry ingestion layer** for OpenObserve in KubeAid. It collects logs,
metrics, traces, and Kubernetes object state from the cluster and ships them to OpenObserve over OTLP.

It also scrapes Prometheus-compatible targets (cadvisor, kube-state-metrics, CoreDNS, annotated pods, etc.), which is
how OpenObserve pulls cluster metrics alongside logs. Metric alerting in Prometheus/Alertmanager is unchanged — see
[Monitoring](../../../../docs/monitoring.md).

For OpenObserve installation and configuration, see the [OpenObserve chart README](../../README.md).

---

This chart deploys an OpenTelemetry Collector stack (agent DaemonSet + gateway StatefulSet) that collects logs, metrics, traces, and Kubernetes object state from your cluster and ships them to OpenObserve.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Every Node  — Agent DaemonSet                      │
│  • Pod/container logs     (filelog receiver)        │
│  • Node host metrics      (hostmetrics receiver)    │
│  • Pod/container metrics  (kubeletstats receiver)   │
└──────────────────────────┬──────────────────────────┘
                           │ OTLP
┌──────────────────────────▼──────────────────────────┐
│  Gateway StatefulSet (1 replica)                    │
│  • Kubernetes events       (k8sobjects/events)      │
│  • Kubernetes object state (k8sobjects/*)           │
│  • Prometheus scraping     (prometheus receiver)    │
│    ├─ cadvisor (container FS IOPS)                  │
│    ├─ kube-state-metrics                            │
│    ├─ CoreDNS                                       │
│    ├─ kube-apiserver                                │
│    ├─ kube-scheduler                                │
│    ├─ kube-controller-manager                       │
│    └─ prometheus-autodiscovery (annotated pods)     │
│  • Distributed traces      (otlp receiver)          │
│  • Service graph metrics   (servicegraph connector) │
└──────────────────────────┬──────────────────────────┘
                           │ OTLP HTTP
              ┌────────────▼────────────┐
              │   OpenObserve Cloud     │
              │   api.openobserve.ai    │
              └─────────────────────────┘
```

## OpenObserve Streams

| Stream | Signal | Source |
|--------|--------|--------|
| `default` (logs) | Logs | Pod/container stdout/stderr |
| `k8s_events` | Logs | Kubernetes Events API |
| `k8s_objects` | Logs | Kubernetes object state (nodes, deployments, etc.) |
| `default` (metrics) | Metrics | kubeletstats, hostmetrics, prometheus, k8s_cluster |
| `default` (traces) | Traces | OTLP instrumented apps |

## Documentation Index

| File | What it covers |
|------|----------------|
| [logs.md](logs.md) | Container logs and Kubernetes events |
| [metrics.md](metrics.md) | All metrics sources and metric names |
| [k8s-objects.md](k8s-objects.md) | Kubernetes object state collection |
| [traces.md](traces.md) | Distributed tracing and auto-instrumentation |
| [collection-modes.md](collection-modes.md) | Watch vs pull mode: current config, rationale, and migration impact |
