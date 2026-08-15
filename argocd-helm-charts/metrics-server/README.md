# Metrics Server

[Metrics Server](https://github.com/kubernetes-sigs/metrics-server) is a cluster-wide aggregator of
resource usage data (CPU/memory) that serves the `metrics.k8s.io` API. It's the source `kubectl top`
and the Kubernetes-native `HorizontalPodAutoscaler` read from.

This is a thin wrapper (chart version 0.5.0) around the upstream `metrics-server` chart (currently
pinned to `3.13.1`, from `https://kubernetes-sigs.github.io/metrics-server/`) with KubeAid defaults
layered on top.

## Why it's in KubeAid

`metrics.k8s.io` is a prerequisite for CPU/memory-based HPAs and for `kubectl top node`/`kubectl top
pod`, both of which KubeAid clusters rely on out of the box.

## Key values / KubeAid-specific configuration

- `metrics-server.args` sets `--kubelet-preferred-address-types=InternalIP` and
  `--kubelet-insecure-tls`, so Metrics Server can scrape kubelets that present self-signed
  certificates (the default on most clusters) via their internal IP rather than a hostname.
- `metrics-server.revisionHistoryLimit: 0` — no old ReplicaSets kept around.
- `networkpolicies` (default `false`) — when set to `true`, renders a Calico-flavored
  `NetworkPolicy` (`crd.projectcalico.org/v1`) restricting Metrics Server to: egress to the
  apiserver (443) and to kubelets on every node (10250, 10255), and ingress on 4443 from the
  control plane only.

## Operational notes

`Chart.yaml` currently points at the upstream `kubernetes-sigs.github.io/metrics-server` repo as a
stand-in for the `stevehipwell` mirror, pending resolution of
[kubernetes-sigs/metrics-server#572](https://github.com/kubernetes-sigs/metrics-server/issues/572);
the dependency should move once
[kubernetes-sigs/metrics-server#670](https://github.com/kubernetes-sigs/metrics-server/pull/670) is
merged. There's also a commented-out `oci://ghcr.io/Obmondo` line for switching to an internal
mirror.

## Docs links

- Upstream chart: <https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server>
- Metrics Server project: <https://github.com/kubernetes-sigs/metrics-server>
- Kubernetes resource metrics pipeline: <https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/>
