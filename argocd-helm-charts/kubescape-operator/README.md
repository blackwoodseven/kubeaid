# Kubescape Operator

Wrapper around the [Kubescape Operator](https://kubescape.io) Helm chart (upstream `kubescape-operator`
v1.40.3). Kubescape scans images for vulnerabilities (via the Kubevuln component and the Grype engine),
detects runtime threats with eBPF (via node-agent), and continuously evaluates cluster security posture
against CIS/NSA-CISA/Pod Security Standards.

## Why it's in KubeAid

Provides in-cluster vulnerability scanning and runtime threat detection without a separate management
plane, alongside the rest of KubeAid's security tooling (`trivy-operator`, `vuls-dictionary`).

## Key values / KubeAid-specific configuration

Set under the `kubescape-operator.capabilities` key:

| Value | Description | Default |
|---|---|---|
| `capabilities.scanEmbeddedSBOMs` | Scan SBOMs embedded inside a container, if found | `enable` |
| `capabilities.runtimeDetection` | eBPF-based runtime threat detection (node-agent) | `enable` |
| `capabilities.malwareDetection` | Node malware scanning via ClamAV | `enable` |
| `capabilities.continuousScan` | Continuously monitor the cluster and refresh security reports | `enable` |
| `capabilities.manageWorkloads` | Automatic seccomp profile suggestions | `enable` |
| `capabilities.syncSBOM` | SBOM sync | `enable` |
| `alertCRD.installDefault` | Install Kubescape's default runtime-threat-detection rule set | `true` |
| `serviceScanConfig.enabled` | Enable service scanning | `true` |

## Operational notes

- Image scanning (Kubevuln/Grype) is triggered on new/changed workloads and by a daily `kubevuln-scheduler`
  CronJob.
- Runtime threat detection uses Inspektor Gadget for eBPF event acquisition and stores findings via
  Kubescape Storage; alerts can be routed to logs or Prometheus Alertmanager.
- Relevancy filtering and Network Policy generation are also part of the default install (see upstream docs).

## Docs links

- [Kubescape docs](https://kubescape.io/docs/)
- [Kubescape Operator vulnerabilities](https://kubescape.io/docs/operator/vulnerabilities/)
- [Kubescape runtime threat detection](https://kubescape.io/docs/operator/runtime-threat-detection/)
- [Kubescape relevancy](https://kubescape.io/docs/operator/relevancy/)
- [Kubescape Network Policy generation](https://kubescape.io/docs/operator/network-policy-generation/)
- Related: [`trivy-operator`](../trivy-operator), [`vuls-dictionary`](../vuls-dictionary)
