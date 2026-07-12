# KubeArmor

[KubeArmor](https://kubearmor.io) is a CNCF runtime-security engine (by AccuKnox)
that uses **eBPF** for observability and **Linux Security Modules** (AppArmor,
BPF-LSM, SELinux) for **inline enforcement** on Kubernetes. It runs as a
DaemonSet and can restrict process execution, file access, network, and
capabilities per workload — denying an operation *at the LSM hook before it
runs*, rather than reacting after the fact.

It complements the [`tetragon`](../tetragon) chart:

| | Tetragon | KubeArmor |
| - | - | - |
| Strength | Security **observability** / forensics (eBPF events) | **Inline enforcement** / workload hardening (LSM) |
| Enforcement | `SIGKILL` after detection | LSM denies the operation before it executes |
| Policy CRD | `TracingPolicy` | `KubeArmorPolicy` (+ least-privilege auto-discovery) |

Pick per cluster by goal: Tetragon for deep observability alongside Cilium;
KubeArmor for preventive hardening and compliance posture. Running both is
possible but usually unnecessary.

Upstream chart: [kubearmor-operator](https://github.com/kubearmor/KubeArmor)
(installed via the operator, which deploys KubeArmor from a `KubeArmorConfig`).

## Prerequisites

- A Linux Security Module on every node. **BPF-LSM** needs kernel >= 5.7 booted
  with `lsm=...,bpf`; otherwise KubeArmor uses **AppArmor** or **SELinux** where
  available. On managed clusters, confirm the node OS ships one of these.
- KubeArmor runs privileged (host mounts, eBPF/LSM access) per the operator.

## Behaviour

- **Observability-first by default.** All postures ship as `audit`: violations
  are logged, nothing is blocked. Nothing is enforced until you opt in.
- **Enforcement is opt-in.** Set a posture to `block` (below) and/or apply a
  `KubeArmorPolicy` / `KubeArmorHostPolicy` with `Block` actions:

  ```yaml
  # values.yaml
  kubearmor-operator:
    kubearmorConfig:
      defaultFilePosture: block
      defaultNetworkPosture: block
  ```

  ```sh
  kubectl apply -f my-kubearmor-policy.yaml
  karmor logs           # stream alerts/telemetry (via the relay)
  ```

## Shipping events to OpenObserve

With `enableStdOutAlerts: true` (the default here), KubeArmor's relay prints
policy-violation alerts to its container **stdout**. Because those become
ordinary pod logs, the existing `openobserve-collector` **agent DaemonSet**
(which tails `/var/log/pods`) picks them up and ships them to OpenObserve — no
KubeArmor-side configuration required.

```
KubeArmor relay ── enableStdOutAlerts ──► stdout ( = /var/log/pods )
                                             │
                                             ▼
   openobserve-collector agent DaemonSet (filelog receiver)
                                             │  otlphttp exporter
                                             ▼
                          in-cluster OpenObserve router
```

Enable `enableStdOutLogs: true` for full visibility telemetry (higher volume).
To route security events to a different/remote OpenObserve, add a second
exporter + namespace-filtered pipeline in the `openobserve-collector` values —
KubeArmor itself is unchanged.

## Configuration

Operator values live under the `kubearmor-operator` key; override them in your
cluster's values file. See the
[upstream operator values](https://github.com/kubearmor/KubeArmor/blob/main/deployments/helm/KubeArmorOperator/values.yaml)
and the [KubeArmor docs](https://docs.kubearmor.io/).
