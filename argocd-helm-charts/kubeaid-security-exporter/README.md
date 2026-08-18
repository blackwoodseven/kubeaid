# kubeaid-security-exporter

Deploys the [KubeAid Security Exporter](https://gitea.obmondo.com/EnableIT/kubeaid-security-exporter) — a
Kubernetes-native exporter that reads a cluster's security posture and reports it as Prometheus metrics and
a JSON API. It only ever reads: no Kubernetes object is created, mutated, or deleted.

What it collects, where the relevant operator is installed:

- **Vulnerabilities and least-privilege findings** from Trivy Operator's report CRs — full CVE detail
  (CVSS score, installed and fixed version, advisory link), rather than the lossy Prometheus projection.
- **Or the same from Kubescape**, read through its aggregated APIService, with per-CVE relevancy —
  whether the vulnerable code actually loaded. The two scanners are alternatives, never merged.
- **Upgrade availability**, by joining those findings against version-checker on canonical image
  references resolved in Go. Rebuilding image references in PromQL fails silently.
- **Network enforcement** from Cilium — whether policy is actually realised on an app's pods, which is a
  different question from whether the app ships a policy.
- **Runtime detection posture** from Tetragon and KubeArmor — which engines are armed, and whether they
  observe or enforce.

None of those are required. Each source is detected through API discovery, and an absent operator is
reported as absent rather than as a failure or as a clean result.

## Relationship to kubeaid-agent

The exporter collects; it never talks to the Obmondo API. `kubeaid-agent` GETs `/api/v1/security-posture`
from this Service and forwards the snapshot, so reporting posture off-cluster is the agent's concern and
cluster read access is this chart's. That split is why the agent holds no CRD access at all.

Deploying this chart without the agent is fine — the metrics and the JSON API work standalone.

## Prerequisites

- **A vulnerability scanner** — either **trivy-operator** or **kubescape-operator**. Without one the
  exporter reports no findings, and says so rather than reporting a clean cluster.
- **version-checker**, for upgrade availability. Without it findings still ship, with upgrade availability
  unknown rather than "up to date".
- kube-prometheus, if `serviceMonitor` / `prometheusRule` stay enabled (both default to `true`).

Cilium, Tetragon and KubeArmor are read when present and skipped when not.

### Which scanner is used

Exactly one, chosen by API discovery: **Trivy takes precedence, Kubescape is used where Trivy is
absent.** Merging them would double-count the same CVE from two databases that disagree at the
margins, and switching an existing cluster's scanner rewrites every finding's ID, score and link at
once — which reads as mass CVE churn rather than as a configuration change. A cluster running both
logs which one it picked; the snapshot names it in `scanner`.

Two fields differ by scanner, and both are absent rather than false when unanswerable:

| Field | Trivy | Kubescape |
|---|---|---|
| `relevant` (did the vulnerable code load) | never — Trivy cannot observe runtime | when the eBPF node-agent runs |
| `os.eosl` (base image past end of life) | yes | never — Grype has no end-of-life data |

## Key values

| Value | Default | Meaning |
|---|---|---|
| `exporter.interval` | `12h` | Collection cadence. Trivy refreshes its reports on a 24h TTL, so polling faster re-reads identical data. |
| `exporter.port` | `8080` | Serves `/healthz`, `/readyz`, `/metrics` and `/api/v1/security-posture`. |
| `prometheusRule.upgradableThreshold` | `20` | `ImageOutdatedAndVulnerable` fires above this many images having both a fixable Critical/High CVE and a newer tag available. |
| `prometheusRule.upgradableFor` | `24h` | How long the count must hold before the alert fires. |

## Alerting

One alert, `ImageOutdatedAndVulnerable`. It is a count, so it fires once per cluster rather than once per
image, and the threshold is deliberately high — every real cluster carries a few of these at any moment, so
a low threshold fires everywhere on day one and gets ignored. The signal worth acting on is a pile of easy
upgrades, not the existence of one.

Collection status is exported as `security_exporter_collection` (1 ok, 0 failed, -1 not installed) but is
deliberately not alerted on: a collection failure is a debugging signal, not something worth paging for.

## Operational notes

- RBAC is least-privilege by construction — a purpose-built ClusterRole granting exactly the verbs the code
  calls, with no `watch` anywhere since the exporter builds no informers. Every rule is consumed through a
  dynamic client, so none of those resource names appear in Go source; removing a rule fails silently and
  renders the cluster as clean rather than erroring.
- Runs unprivileged: non-root, read-only root filesystem, all capabilities dropped, `RuntimeDefault` seccomp.
- A collection pass holds every VulnerabilityReport in memory at once, so the memory ceiling scales with
  image count rather than with request rate.

## Docs links

- Chart source: `templates/` and [values.yaml](./values.yaml) in this directory (documented inline).
- Obmondo: <https://obmondo.com>
