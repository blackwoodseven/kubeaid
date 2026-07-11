# Tetragon

[Tetragon](https://tetragon.io) is a CNCF project (by Isovalent/Cilium) that
uses eBPF for security observability and runtime enforcement on Kubernetes. It
runs as a DaemonSet and surfaces process execution, network activity and file
access as low-overhead kernel events, and can optionally enforce policy in the
kernel (for example killing a process that violates a rule).

Upstream chart: [https://helm.cilium.io/](https://github.com/cilium/tetragon) (sources: [https://github.com/cilium/tetragon](https://github.com/cilium/tetragon))

## Prerequisites

- A Linux kernel with BTF and eBPF support on every node
  (kernel >= 5.4 with `CONFIG_DEBUG_INFO_BTF=y`). Most modern distro kernels
  ship this; check `/sys/kernel/btf/vmlinux` exists on the node.
- Tetragon runs on the host network and mounts host paths; it needs the
  privileges granted by the upstream chart's DaemonSet.

## Usage

- Installed as-is, Tetragon is **observability-only**: it emits process,
  network and file events (JSON export + gRPC). Nothing is blocked.
- Inspect events from a node with the `tetra` CLI:

  ```sh
  kubectl exec -n <namespace> ds/tetragon -c tetragon -- \
    tetra getevents -o compact
  ```

- **Enforcement is opt-in.** Apply a `TracingPolicy` (cluster-wide) or
  `TracingPolicyNamespaced` with enforcement actions (e.g. `Sigkill`,
  `Override`) to block behaviour at runtime:

  ```sh
  kubectl apply -f my-tracing-policy.yaml
  ```

  Tetragon integrates naturally with Cilium (same vendor), which KubeAid
  already uses as the CNI.

## Configuration

All values are kept at upstream defaults; override them under the `tetragon:`
key in your cluster's values file. See the
[upstream values](https://github.com/cilium/tetragon/blob/main/install/kubernetes/tetragon/values.yaml)
and the [Tetragon docs](https://tetragon.io/docs/) for details.
