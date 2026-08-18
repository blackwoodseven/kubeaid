# KubeAid Agent

The KubeAid Agent (`ghcr.io/obmondo/kubeaid-agent`) is Obmondo's in-cluster agent. It authenticates to the
Obmondo API over mTLS and reports cluster state — node counts, Kubernetes version, security posture — and can run
Argo CD syncs during agreed service windows. This chart is authored in KubeAid (not a vendored upstream wrapper).

## What this chart deploys

Two Deployments from one Argo CD application:

| Workload | Purpose |
|---|---|
| `kubeaid-agent` | Talks to the Obmondo API over mTLS. Holds the credential; holds no CRD access. |
| `kubeaid-security-exporter` | Collects the cluster's security posture and serves it at `/api/v1/security-posture`. Holds cluster-wide read; talks to nothing outside the cluster. |

They are **two Deployments with two ServiceAccounts, not one pod with a sidecar**. A pod carries a single
ServiceAccount, so co-locating them would hand the workload holding the Obmondo credential the exporter's
cluster-wide read across seven API groups — the coupling that separating them removed in the first place.
Keeping them apart also bounds the blast radius: a collection pass holds every VulnerabilityReport in memory
at once, and as a sidecar an OOM there would take down the agent, and with it the cluster-liveness ping.

Set `securityExporter.enabled: false` to run the agent alone.

## Why it's in KubeAid

It is the link between a KubeAid cluster and the Obmondo platform. On clusters with `obmondo.monitoring` enabled,
`kubeaid-cli` deploys it as the `kubeaid-agent` Argo CD app (namespace `obmondo`), seals the mTLS client cert into
the `obmondo-clientcert` Secret, and creates the Argo CD project-role token the agent uses: a `kubeaid-agent` role
on the `kubeaid` Argo CD project, stored in the `argocd-project-role-kubeaid-agent` Secret (kubeaid-cli ≥ v0.22.4).

## Prerequisites

- `obmondo-clientcert` Secret in the release namespace: the mTLS client certificate (`tls.crt`, `tls.key`,
  `ca.crt`) issued during Obmondo onboarding. Name overridable via `obmondoAPITLSSecretName`.
- `argocd-project-role-kubeaid-agent` Secret in the `argocd` namespace, holding the Argo CD auth token under the
  `token` key (created automatically by `kubeaid-cli`). Name overridable via
  `appConfig.argocd.authTokenSecretName`.
- kube-prometheus, if `serviceMonitor` / `securityExporter.prometheusRule` stay enabled (all default to `true`).

The exporter additionally wants, but does not require:

- **A vulnerability scanner** — either **trivy-operator** or **kubescape-operator**. Without one it reports no
  findings, and says so rather than reporting a clean cluster.
- **version-checker**, for upgrade availability. Without it findings still ship, with upgrade availability
  unknown rather than "up to date".

Cilium, Tetragon and KubeArmor are read when present and skipped when not.

## Key values / KubeAid-specific configuration

`appConfig` is rendered verbatim into the agent's config file (a ConfigMap mounted at
`/etc/kubeaid-agent/config.yaml`); a config change triggers a rollout via a checksum annotation.

| Value | Default | Meaning |
|---|---|---|
| `appConfig.obmondoAPI.url` | `https://api.obmondo.com/api` | Obmondo API endpoint (mTLS). |
| `appConfig.kubeaidUpdate.enabled` | `false` | Opt-in: schedule the service-window Argo CD sync cron job. |
| `appConfig.kubeaidUpdate.checkInterval` | `15m` | Poll cadence for an active KubeAid update service window. |
| `appConfig.securityPosture.enabled` | `true` | Poll the exporter and forward its snapshots to the Obmondo API. The agent collects nothing itself. |
| `appConfig.securityPosture.exporterURL` | `http://kubeaid-security-exporter` | In-cluster URL of the exporter. Matches the Service this chart creates — change both or neither. |
| `appConfig.securityPosture.pollInterval` | `1h` | Poll cadence. The submit is skipped when `collectedAt` has not advanced, so end-to-end freshness is bounded by `securityExporter.exporter.interval`, not by this. |
| `obmondoAPITLSSecretName` | `obmondo-clientcert` | Secret with the mTLS keypair. |
| `extraSecretReaderNamespaces` | `[]` | Extra namespaces where a secrets-read Role/RoleBinding is created for the agent. |
| `securityExporter.enabled` | `true` | Deploy the exporter alongside the agent. |
| `securityExporter.exporter.interval` | `12h` | Collection cadence. Trivy refreshes its reports on a 24h TTL, so polling faster re-reads identical data. |
| `securityExporter.prometheusRule.upgradableThreshold` | `20` | `ImageOutdatedAndVulnerable` fires above this many images having both a fixable Critical/High CVE and a newer tag available. |
| `securityExporter.prometheusRule.upgradableFor` | `24h` | How long the count must hold before the alert fires. |

## What the exporter collects

Each source is detected through API discovery and skipped when absent.

- **Vulnerabilities and least-privilege findings** from Trivy Operator's report CRs — full CVE detail
  (CVSS score, installed and fixed version, advisory link), rather than the lossy Prometheus projection.
- **Or the same from Kubescape**, read through its aggregated APIService, with per-CVE relevancy — whether the
  vulnerable code actually loaded. The two scanners are alternatives, never merged.
- **Upgrade availability**, by joining findings against version-checker on canonical image references resolved
  in Go. Rebuilding image references in PromQL fails silently.
- **Network enforcement** from Cilium — whether policy is actually realised on an app's pods, which is a
  different question from whether the app ships a policy.
- **Runtime detection posture** from Tetragon and KubeArmor — which engines are armed, and whether they
  observe or enforce.

### Which scanner is used

Exactly one, chosen by API discovery: **Trivy takes precedence, Kubescape is used where Trivy is absent.**
Merging them would double-count the same CVE from two databases that disagree at the margins, and switching an
existing cluster's scanner rewrites every finding's ID, score and link at once — which reads as mass CVE churn
rather than as a configuration change. The snapshot names the one it used in `scanner`.

Two fields differ by scanner, and both are absent rather than false when unanswerable:

| Field | Trivy | Kubescape |
|---|---|---|
| `relevant` (did the vulnerable code load) | never — Trivy cannot observe runtime | when the eBPF node-agent runs |
| `os.eosl` (base image past end of life) | yes | never — Grype has no end-of-life data |

## Alerting

One alert, `ImageOutdatedAndVulnerable`. It is a count, so it fires once per cluster rather than once per
image, and the threshold is deliberately high — every real cluster carries a few of these at any moment, so a
low threshold fires everywhere on day one and gets ignored. The signal worth acting on is a pile of easy
upgrades, not the existence of one.

Collection status is exported as `security_exporter_collection` (1 ok, 0 failed, -1 not installed) but is
deliberately not alerted on: a collection failure is a debugging signal, not something worth paging for.

## Operational notes

- RBAC is least-privilege by construction, and **separate per workload**: the agent gets a purpose-built
  ClusterRole granting exactly the verbs its code calls, with secrets access on namespaced Roles and no CRD
  access at all. The exporter gets its own, covering the report CRs it reads. Neither can use the other's.
- No `watch` anywhere — neither workload builds informers.
- The exporter's rules are all consumed through a dynamic client, so no Go source references those resource
  names; removing a rule fails silently and renders the cluster as clean rather than erroring.
- `appConfig.securityPosture.enabled: true` is safe where the exporter is disabled — the poll fails, a metric
  records it, and nothing is submitted. Set it to `false` only where vulnerability detail must not leave the
  cluster.
- Both run unprivileged: non-root, all capabilities dropped, `RuntimeDefault` seccomp; the exporter also runs
  with a read-only root filesystem.

## Docs links

- Chart source: `templates/` and [values.yaml](./values.yaml) in this directory (documented inline).
- Exporter source: <https://gitea.obmondo.com/EnableIT/kubeaid-security-exporter>
- Obmondo: <https://obmondo.com>
