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

## Shipping events to OpenObserve

Tetragon defaults to `export.mode: "stdout"`: an `export-stdout` sidecar tails the
JSON export file (`/var/run/cilium/tetragon/tetragon.log`) and prints each event to
the container's **stdout**. Because those events become ordinary pod logs, the
existing `openobserve-collector` **agent DaemonSet** (which already tails
`/var/log/pods`) picks them up and ships them to OpenObserve — no Tetragon-side
configuration required.

### Default: local, in-cluster OpenObserve

```
Tetragon DaemonSet
  ├─ tetragon        → writes JSON events to /var/run/cilium/tetragon/tetragon.log
  └─ export-stdout   → tails the file → stdout ( = /var/log/pods )
                                          │
                                          ▼
     openobserve-collector agent DaemonSet (filelog receiver)
                                          │  otlphttp exporter
                                          ▼
                       in-cluster OpenObserve router
       http://openobserve-router.openobserve.svc.cluster.local:5080/api/default
```

This is the default: security events land in the same local OpenObserve as the rest
of the cluster telemetry.

### Routing to a different or remote OpenObserve

*Where* the events land is decided by the OTel Collector's exporter, not by Tetragon.
To send security events to a separate (or internet-facing) OpenObserve — e.g. a
central SIEM-style instance — while application logs stay local, add a second
exporter and a routing/filter pipeline in the `openobserve-collector` values that
selects the Tetragon namespace, for example:

```yaml
exporters:
  otlphttp/openobserve_security:
    endpoint: https://openobserve.security.example.com/api/default
    headers:
      Authorization: Basic <base64-auth>   # from a sealed secret
      stream-name: tetragon
service:
  pipelines:
    logs/tetragon:
      receivers: [filelog/std]
      processors: [memory_limiter, k8sattributes, batch]   # + a filter on k8s.namespace.name
      exporters: [otlphttp/openobserve_security]
```

Tetragon itself is unchanged; only the collector's exporter/pipeline differs.
