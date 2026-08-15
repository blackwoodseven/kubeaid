# Tigera Operator

Wrapper chart for the upstream [`tigera-operator`](https://github.com/projectcalico/calico) chart (pinned to
`v3.32.1`), the operator that installs and manages [Calico](https://www.tigera.io/project-calico/) — pod
networking, network policy, and (via this chart's `bgpConfiguration.yaml` template) BGP peering.

## Why it's in KubeAid

**Cilium is KubeAid's default CNI** (see [`cilium`](../cilium)); this chart is not wired into `kubeaid-cli`'s
bootstrap flow anywhere — no `pkg/constants/templates.go` entry references it. Git history shows it predates the
move to Cilium (added as "calico chart" in the earliest commits, later renamed to `tigera-operator`), and
`docs/operations/operations-tips.md` — itself marked legacy/outdated — describes a Calico-CNI-based network
filtering design that reflects that earlier setup. The chart is still version-bumped automatically alongside every
other vendored chart (see `CHANGELOG.md`), which keeps it current without implying it's part of the standard
bootstrap path.

Treat this as a **legacy/provider-specific chart**: kept in-repo and up to date for clusters that were bootstrapped
with Calico (or that have a specific reason to run it instead of Cilium), not for new KubeAid clusters.

## Key values / KubeAid-specific configuration

- `netbird.enabled` (default `"false"` string, `values.yaml`) — when `"true"`, `templates/bgpConfiguration.yaml`
  renders a Calico `BGPConfiguration` (`nodeToNodeMeshEnabled: true`, `asNumber: 64512`) that also adds `wt0`
  (NetBird's WireGuard interface) to `ignoredInterfaces`, so Calico's BGP mesh doesn't try to route over NetBird's
  interface.

## Docs links

- Upstream project: <https://github.com/projectcalico/calico>
- Upstream Helm repo: <https://projectcalico.docs.tigera.io/charts>
- Calico docs: <https://docs.tigera.io/calico>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
