# KubeAid Agent

The KubeAid Agent (`ghcr.io/obmondo/kubeaid-agent`) is Obmondo's in-cluster agent. It authenticates to the
Obmondo API over mTLS and reports cluster state — node counts, Kubernetes version, security posture — and can run
Argo CD syncs during agreed service windows. This chart is authored in KubeAid (not a vendored upstream wrapper).

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
- kube-prometheus, if `serviceMonitor` / `prometheusRule` stay enabled (both default to `true`).

## Key values / KubeAid-specific configuration

`appConfig` is rendered verbatim into the agent's config file (a ConfigMap mounted at
`/etc/kubeaid-agent/config.yaml`); a config change triggers a rollout via a checksum annotation.

| Value | Default | Meaning |
|---|---|---|
| `appConfig.obmondoAPI.url` | `https://api.obmondo.com/api` | Obmondo API endpoint (mTLS). |
| `appConfig.kubeaidUpdate.enabled` | `false` | Opt-in: schedule the service-window Argo CD sync cron job. |
| `appConfig.kubeaidUpdate.checkInterval` | `15m` | Poll cadence for an active KubeAid update service window. |
| `appConfig.securityPosture.enabled` | `true` | Collect vulnerabilities (trivy-operator reports), least-privilege findings, network-policy and runtime-detection posture, and submit them to the Obmondo API. Also gates the matching RBAC and the PrometheusRule. |
| `appConfig.securityPosture.interval` | `12h` | Full posture collection cadence (Trivy refreshes reports every 24h). |
| `obmondoAPITLSSecretName` | `obmondo-clientcert` | Secret with the mTLS keypair. |
| `extraSecretReaderNamespaces` | `[]` | Extra namespaces where a secrets-read Role/RoleBinding is created for the agent. |
| `prometheusRule.upgradableThreshold` | `20` | `ImageOutdatedAndVulnerable` fires when more images than this have both a fixable Critical/High CVE and a newer tag (for `upgradableFor`, default 24h). |

## Operational notes

- RBAC is least-privilege by construction: a purpose-built ClusterRole grants exactly the verbs the agent's code
  calls (no `watch`, no blanket `view`). Secrets access stays on namespaced Roles. The security-posture rules
  (trivy-operator, Cilium/Tetragon, KubeArmor resources) are gated by the same `securityPosture.enabled` flag the
  agent reads, so RBAC and behaviour cannot disagree.
- `securityPosture.enabled: true` is safe on clusters without a scanner — the collector detects missing APIs via
  discovery and does nothing. Set it to `false` only where vulnerability detail must not leave the cluster.
- Runs unprivileged: non-root, all capabilities dropped, `RuntimeDefault` seccomp.

## Docs links

- Chart source: `templates/` and [values.yaml](./values.yaml) in this directory (documented inline).
- Obmondo: <https://obmondo.com>
