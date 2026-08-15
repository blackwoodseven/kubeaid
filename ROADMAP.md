# Roadmap

Most of what KubeAid set out to do is shipped — the [README](./README.md#features) lists the feature set and
[Technical Details on the Features](./docs/kubeaid/features-technical-details.md) documents the implementation
status of each piece. This roadmap lists what is genuinely open.

This reflects current priorities and will shift as the project and its users grow; it isn't a committed release
schedule.

## Cluster lifecycle

- **`cluster recover` for cloud and managed control planes** — recovery is wired for self-managed AWS/Azure;
  EKS and AKS clusters currently re-bootstrap and restore from Velero backups manually.
- **Hetzner day-2 parity** — `cluster upgrade` and `cluster recover` for Hetzner Cloud, Bare Metal and hybrid
  clusters are work in progress (see the
  [kubeaid-cli provider matrix](https://github.com/Obmondo/kubeaid-cli#cloud-providers)).
- **Day-2 `cluster sync` beyond bare metal** — reconciling config changes onto running Cluster API clusters;
  tracked in the [kubeaid-cli roadmap](https://github.com/Obmondo/kubeaid-cli/blob/main/ROADMAP.md).

## Resilience

- **Live cluster migration** — moving applications or whole clusters between environments (for example built on
  Cilium Cluster Mesh), which also unlocks major upgrades via a shadow cluster with seamless switchover.
- **Full air-gapped operation** — maintaining an in-cluster copy of every container image in use and pointing
  all charts at it. Harbor proxy-cache with the kyverno rewrite policy covers clusters that deploy Harbor;
  the platform-wide flow is still open.

## Contributing to the roadmap

Have a use case this doesn't cover, or want to work on one of the items above? Open an
[issue](https://github.com/Obmondo/KubeAid/issues) — see [CONTRIBUTING.md](./CONTRIBUTING.md) for how to get
started.
