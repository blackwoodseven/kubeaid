# SmartMon Exporter

Wrapper around the upstream [prometheus-smartctl-exporter](https://github.com/prometheus-community/smartctl_exporter)
Helm chart (v0.17.1). Runs `smartctl` against block devices and exposes S.M.A.R.T. disk health metrics for
Prometheus to scrape.

## Why it's in KubeAid

Gives Prometheus visibility into physical disk health (reallocated sectors, pending sectors, temperature,
and other S.M.A.R.T. attributes) on nodes with local/bare-metal storage - the same metric this chart exposes
also backs the `smartmon` alert rules in [`prometheus-linuxaid`](../prometheus-linuxaid) for LinuxAid-managed
servers.

## Prerequisites

- Runs as a DaemonSet with access to the host's block devices; nodes without local disks (e.g. pure
  cloud-managed-disk nodes) gain nothing from it.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `prometheus-smartctl-exporter.serviceMonitor.enabled` | Create a ServiceMonitor for kube-prometheus | `true` |
| `prometheus-smartctl-exporter.serviceMonitor.relabelings` | Relabel `__meta_kubernetes_pod_node_name` to `instance`, so metrics are keyed by node rather than pod | set (see `values.yaml`) |

## Docs links

- [smartctl_exporter](https://github.com/prometheus-community/smartctl_exporter)
- Related: [`prometheus-linuxaid`](../prometheus-linuxaid)
