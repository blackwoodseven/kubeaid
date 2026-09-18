# linuxaid-security-exporter

Reports every node's installed packages to a [Vuls](https://vuls.io) server, which matches them
against CVE data, and exposes the findings as Prometheus metrics. It is the node-OS counterpart to
the scanners KubeAid already runs: Trivy and Kubescape look at container images, this looks at the
operating system underneath them.

## Why it's in KubeAid

Nothing else in the cluster answers "which CVEs are the nodes themselves exposed to". LinuxAid runs
[the same exporter](https://github.com/Obmondo/security-exporter) as a systemd service on ordinary
servers; this chart runs it on cluster nodes, reporting to the same Vuls server, so nodes and
servers are scanned by one pipeline.

Not to be confused with `security-exporter` in the [kubeaid-agent](../kubeaid-agent) chart, which
collects the cluster's security posture through the Kubernetes API.

## How it works

A DaemonSet places one pod on every node. Each pod:

1. reads its node's package database through a read-only mount — `dpkg-query --admindir` on Debian
   and Ubuntu, `rpm --dbpath` on RHEL and SUSE families;
2. posts the package list to the Vuls server over mTLS, using the cluster's client certificate;
3. serves the CVEs that come back as Prometheus metrics, and scans again every `scanInterval`.

The pod runs as an ordinary user with every capability dropped, a read-only root filesystem and no
service-account token. It needs no `privileged`, no `hostPID`, no `hostNetwork` and no RBAC, because
it reads two world-readable paths and talks to one server.

Reports in Vuls are named after the certificate's common name. Every node shares the cluster's
certificate, so each scan also carries its node name, taken from the downward API, to tell the
reports apart.

## Prerequisites

- **The `obmondo-clientcert` Secret** in the release namespace, with `tls.crt` and `tls.key`. Besides
  authenticating to the Vuls server, its common name is what the reports are filed under, so a
  self-hosted setup needs a certificate too. It is the certificate Obmondo issues for the cluster; `kubeaid-cli` seals it into both the `obmondo` and
  `monitoring` namespaces on clusters with `obmondo.monitoring` enabled, so either works. The
  examples here use `monitoring`, next to node-exporter and the Prometheus stack.
- **Nodes running Debian, Ubuntu, RHEL, CentOS, Rocky, Oracle Linux or SLES.** The package database
  of anything else is not read.
- **A Vuls server to report to.** Obmondo-managed clusters use the hosted `https://vuls.obmondo.com`,
  which is the default and needs nothing else. Anyone else hosts it themselves: the
  [vuls-dictionary](../vuls-dictionary) chart deploys the server together with the nightly CVE database,
  roughly 7 GB uncompressed on a 25 Gi volume, plus a second volume for scan results. Point
  `vulsServer.url` at it.
- **Network access** from the pods to the Vuls server, and from the cluster to `ghcr.io/obmondo`.
- **kube-prometheus**, if `serviceMonitor.enabled` stays `true`.

## Install

Either switch it on with the agent, or deploy it on its own.

**With kubeaid-agent.** The chart is symlinked into
[kubeaid-agent](../kubeaid-agent)'s `charts/`, so one value in that release's
`values-kubeaid-agent.yaml` turns it on, and it lands in the agent's namespace:

```yaml
linuxaid-security-exporter:
  enabled: true
```

**On its own.** Add an Argo CD Application to your kubeaid-config repository, at
`k8s/<cluster>/argocd-apps/templates/linuxaid-security-exporter.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: linuxaid-security-exporter
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  project: kubeaid
  sources:
    - repoURL: https://github.com/Obmondo/KubeAid.git
      path: argocd-helm-charts/linuxaid-security-exporter
      targetRevision: HEAD
      helm:
        valueFiles:
          - $values/k8s/<cluster>/argocd-apps/values-linuxaid-security-exporter.yaml
    - repoURL: <your-config-repo>
      targetRevision: HEAD
      ref: values
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
```

The values file can be empty to start with: the defaults point at `https://vuls.obmondo.com`, Obmondo's
hosted Vuls server, and the `obmondo-clientcert` Secret. Self-hosters can point `vulsServer.url` at their
own server, for example one deployed with the [vuls-dictionary](../vuls-dictionary) chart.

`enabled` is read only when this chart runs as kubeaid-agent's subchart; a standalone Application deploys
it whatever that value says.

## Key values

| Value | Default | Meaning |
|---|---|---|
| `image.repository`, `image.tag` | `ghcr.io/obmondo/security-exporter`, `v2.5.0` | Exporter image. |
| `vulsServer.url` | `https://vuls.obmondo.com` | Where package lists are sent. |
| `vulsServer.timeout` | `5m` | A scan of a few hundred packages is not quick; this is the HTTP timeout. |
| `obmondoClientCert.secretName` | `obmondo-clientcert` | Secret holding `tls.crt` and `tls.key`. |
| `scanInterval` | `12h` | How often each node scans. |
| `randomDelay` | `1h` | Window each pod waits in before its first scan, so a cluster does not hit the server at once. |
| `upstreamRetryDelay` | `6h` | How long metrics keep being served after the server goes unreachable, before the pod exits and Kubernetes restarts it. |
| `hostMounts` | `[{path: /}]` | Node paths mounted read-only under `/host`. The whole root works on any distro; narrowing it to `/var/lib/dpkg` (or `/var/lib/rpm`) and `/etc/os-release` also works, since nothing else is read. |
| `metricsPort` | `63396` | Port the metrics are served on. |
| `serviceMonitor.enabled`, `.interval` | `true`, `30s` | ServiceMonitor for kube-prometheus, relabelled so metrics are keyed by node rather than pod. |
| `tolerations` | tolerate everything | Scan control-plane and tainted nodes too. |
| `nodeSelector` | `{}` | Limit which nodes are scanned. |

## Metrics

`general_cve_details` and `kernel_cve_details` (labelled by application, CVE and score),
`security_exporter_package_high_severity_cves`, `security_exporter_scan_up`,
`security_exporter_last_scan_timestamp`, `security_exporter_scan_duration_seconds`,
`security_exporter_scan_errors_total` and `security_exporter_os_support_end_timestamp`, which carries
each distro's end-of-life dates. The [`prometheus-linuxaid`](../prometheus-linuxaid) rules already
alert on these for LinuxAid servers.

`total_number_of_packages_with_update` and `kernel_update_available` stay empty on nodes: reporting
available updates needs the host's repository metadata and configuration, which this pod does not
mount. CVE matching uses installed versions and is unaffected.

## Docs links

- [security-exporter](https://github.com/Obmondo/security-exporter)
- Related: [`linuxaid-agents`](../linuxaid-agents) runs LinuxAid's OpenVox agent on the same nodes.
