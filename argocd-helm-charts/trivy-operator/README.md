# trivy-operator

Helm chart wrapper for [Trivy Operator](https://aquasecurity.github.io/trivy-operator/) — continuous in-cluster image and Kubernetes resource vulnerability scanning, with Prometheus metrics and pre-baked alert rules.

## How it works

Trivy Operator watches workloads (Deployment, StatefulSet, DaemonSet, Job, CronJob, Pod) across the cluster and emits per-resource scan results as CRDs:

- `VulnerabilityReport` — image-level CVEs
- `ConfigAuditReport` — workload misconfigurations
- `ExposedSecretReport` — leaked credentials in image layers
- `RbacAssessmentReport` — RBAC anti-patterns

A built-in Trivy server is shared across scanners (no per-scan job pulls), and the operator exposes Prometheus metrics so the existing kube-prometheus-stack picks up CVE counts as time series.

## Why this complements Harbor

Harbor scans images **at push time** to a Harbor registry. Trivy Operator scans **what's actually running in the cluster**, regardless of source registry — covering external-pull images (`docker.io`, `quay.io`, `ghcr.io`, etc.) and reflecting CVEs added to the database after the image was pushed.

## Quick start

```yaml
# values.yaml
trivy-operator:
  excludeNamespaces: "kube-system,trivy-system,argocd"
  serviceMonitor:
    enabled: true
  trivy:
    ignoreUnfixed: true
    severity: "CRITICAL,HIGH"

kubeaid:
  prometheusRule:
    enabled: true
```

> **Note:** deploy the [`version-checker`](../version-checker) chart alongside this one. Neither alert
> here depends on it, but `kubeaid-agent` uses its metrics to tell you whether a newer image tag
> actually exists — which is what turns a CVE finding into an upgrade you can apply.

## Configuration

### Upstream chart (`trivy-operator.*`)

Forwarded to the [aquasecurity/trivy-operator](https://artifacthub.io/packages/helm/trivy-operator/trivy-operator) Helm chart. See upstream values.yaml for the full surface; the most relevant knobs are mirrored in this chart's `values.yaml` with KubeAid-friendly defaults.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `trivy-operator.excludeNamespaces` | Namespaces to skip scanning | `"kube-system,trivy-system,argocd"` |
| `trivy-operator.serviceMonitor.enabled` | Create ServiceMonitor for Prometheus scraping | `true` |
| `trivy-operator.operator.metricsVulnIdEnabled` | Emit per-CVE-ID metric labels | `true` |
| `trivy-operator.trivy.ignoreUnfixed` | Drop CVEs with no fix available | `true` |
| `trivy-operator.trivy.severity` | Severities to report | `"CRITICAL,HIGH"` |
| `trivy-operator.trivy.builtInTrivyServer` | Use single in-cluster Trivy server | `true` |

### KubeAid additions (`kubeaid.*`)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kubeaid.prometheusRule.enabled` | Generate PrometheusRule (2 alerts, no recording rules) | `true` |
| `kubeaid.prometheusRule.blindFor` | How long the scanner must report nothing before paging | `1h` |
| `kubeaid.prometheusRule.backlogThreshold` | Fixable Critical/High count above which the backlog alert fires | `100` |
| `kubeaid.prometheusRule.backlogFor` | How long the backlog must exceed the threshold | `24h` |
| `kubeaid.prometheusRule.additionalLabels` | Extra labels added to the PrometheusRule object (for Prometheus selector matching) | `{}` |
| `kubeaid.prometheusRule.additionalAnnotations` | Extra annotations added to the PrometheusRule object | `{}` |

## Alerts shipped

Prometheus answers two questions here and no more — **is the scanner working**, and **is the backlog
growing**. Per-CVE detail is not alerting data.

- `TrivyOperatorMetricsMissing` — `absent(trivy_image_vulnerabilities)`. The scanner is producing
  nothing, so the cluster is **unscanned, not clean**. This is the one vulnerability alert that
  justifies paging: a silent scanner looks exactly like a healthy one, and across a fleet nobody
  notices by eye.
- `ClusterVulnerabilityBacklog` — fixable Critical/High findings above `backlogThreshold`.
  Deliberately a **ticket, never a page**. With `ignoreUnfixed` the count is still never zero on a
  real cluster, so paging on it would be muted within a week — taking the health alert down with it.

### Where the per-CVE detail went

CVSS scores, installed and fixed versions, descriptions and links are **not** in these metrics.
`kubeaid-agent` reads them from the `VulnerabilityReport` CRs — which carry the full record — and
submits them to the Obmondo API for display in the UI, alongside the existing server-page CVE view.

An earlier revision of this chart correlated CVEs against `version-checker` inside a recording rule,
to alert only when a fix was actually available. It joined on an image reference rebuilt from Trivy's
`image_registry` + `image_repository` labels, which meant re-implementing Docker's reference grammar
in chained `label_replace` calls. It failed silently twice: short-form Docker Hub references
(`nginx:1.25`) never matched, and the fix for that wrongly rewrote `localhost/…` references.

That correlation now happens in `kubeaid-agent`, where
[`go-containerregistry`](https://github.com/google/go-containerregistry) already implements the
grammar correctly — the same library Trivy itself uses. A PromQL join can only ever *suppress*
alerts, never add them, which is the wrong failure direction for security data.

> A previous `TrivyOperatorScannerStuck` alert queried `trivy_resource_last_scan_timestamp_seconds`.
> That metric does not exist — trivy-operator exposes no last-scan timestamp of any kind — so it
> could never fire. Scanner liveness is now inferred from whether reports exist at all.

## Useful commands

```bash
# All vulnerable workloads
kubectl get vulnerabilityreports -A

# Critical-only summary
kubectl get vulnerabilityreports -A -o json | jq '.items[] | {ns:.metadata.namespace, res:.report.artifact.repository, crit:.report.summary.criticalCount}'

# Force a re-scan of a workload
kubectl annotate deploy/my-app -n my-ns trivy-operator.aquasecurity.github.io/last-scan-checksum-

# Inspect operator logs
kubectl logs -n trivy-system deploy/trivy-operator -f
```

## Notes

- This chart is a wrapper. Bump `trivy-operator` chart version in `Chart.yaml` to pull upstream fixes.
- For air-gapped clusters, mirror the `aquasec/trivy-db` and `aquasec/trivy-java-db` images and override `trivy-operator.trivy.image.repository` and `trivy.dbRepository`.
- Pairs with `vuls-dictionary` (host-level scanning) — host CVEs go to Vuls, container CVEs go to Trivy Operator.
