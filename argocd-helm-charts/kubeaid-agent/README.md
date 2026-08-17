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
- `kubeaid-security-exporter` in the cluster, if `appConfig.securityPosture.enabled` stays `true`. The agent
  forwards that exporter's snapshots; it collects no posture data itself.
- kube-prometheus, if `serviceMonitor` stays enabled (defaults to `true`).

## Key values / KubeAid-specific configuration

`appConfig` is rendered verbatim into the agent's config file (a ConfigMap mounted at
`/etc/kubeaid-agent/config.yaml`); a config change triggers a rollout via a checksum annotation.

| Value | Default | Meaning |
|---|---|---|
| `appConfig.obmondoAPI.url` | `https://api.obmondo.com/api` | Obmondo API endpoint (mTLS). |
| `appConfig.kubeaidUpdate.enabled` | `false` | Opt-in: schedule the service-window Argo CD sync cron job. |
| `appConfig.kubeaidUpdate.checkInterval` | `15m` | Poll cadence for an active KubeAid update service window. |
| `appConfig.securityPosture.enabled` | `true` | Poll `kubeaid-security-exporter` and forward its snapshots to the Obmondo API. The agent collects nothing itself. |
| `appConfig.securityPosture.exporterURL` | `http://kubeaid-security-exporter` | In-cluster URL of the exporter. A bare Service name resolves in the agent's own namespace; qualify it if the two charts deploy to different namespaces. |
| `appConfig.securityPosture.pollInterval` | `1h` | Poll cadence. The submit is skipped when `collectedAt` has not advanced, so end-to-end freshness is bounded by the exporter's collection interval, not by this. |
| `obmondoAPITLSSecretName` | `obmondo-clientcert` | Secret with the mTLS keypair. |
| `extraSecretReaderNamespaces` | `[]` | Extra namespaces where a secrets-read Role/RoleBinding is created for the agent. |

## Operational notes

- RBAC is least-privilege by construction: a purpose-built ClusterRole grants exactly the verbs the agent's code
  calls (no `watch`, no blanket `view`). Secrets access stays on namespaced Roles. The agent holds no CRD access
  at all — reading Trivy, Cilium, Tetragon and KubeArmor resources belongs to `kubeaid-security-exporter`.
- `securityPosture.enabled: true` is safe where the exporter is not installed — the poll fails, a metric records
  it, and nothing is submitted. Set it to `false` only where vulnerability detail must not leave the cluster.
- Runs unprivileged: non-root, all capabilities dropped, `RuntimeDefault` seccomp.

## Docs links

- Chart source: `templates/` and [values.yaml](./values.yaml) in this directory (documented inline).
- Obmondo: <https://obmondo.com>
