# Version Checker

Wrapper around the upstream [jetstack/version-checker](https://github.com/jetstack/version-checker) Helm
chart (v0.11.0). Scans running container images against their upstream registries and exposes a Prometheus
metric for whether a newer tag is available.

## Why it's in KubeAid

Deploy alongside [`trivy-operator`](../trivy-operator): Trivy Operator finds CVEs in what is running,
version-checker answers "does a newer tag exist upstream" - together they turn a vulnerability finding into
an upgrade someone can actually apply. Neither chart depends on the other operationally.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `version-checker.defaultTestAll` | Scan every container by default. Set `false` and annotate pods with `enable.version-checker.io/<container>=true` to opt in selectively instead | `true` |
| `version-checker.imageCacheTimeout` | How long registry tag lookups are cached; lower = fresher results, more registry traffic | `30m` |
| `version-checker.logLevel` | Log level | `info` |
| `version-checker.serviceMonitor.enabled` | Create a ServiceMonitor for kube-prometheus | `true` |
| `version-checker.serviceMonitor.interval` | Scrape interval | `60s` |
| `version-checker.resources` | Requests/limits | 50m/128Mi requests, 200m/256Mi limits |

## Docs links

- [jetstack/version-checker](https://github.com/jetstack/version-checker)
- Related: [`trivy-operator`](../trivy-operator)
