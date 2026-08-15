# LocalPV Provisioner

Wrapper chart (chart name `dynamic-localpv`) for the upstream
[`localpv-provisioner`](https://github.com/openebs/dynamic-localpv-provisioner) chart (pinned to `4.5.1`, appVersion
`4.5.1`), OpenEBS's dynamic **hostPath** local-PV provisioner.

## Why it's in KubeAid

Rendered on **bare-metal** clusters — `BareMetalSpecificNonSecretTemplateNames` in `kubeaid-cli` (alongside
Cilium and KubeOne), deployed into the `localpv-provisioner` namespace. It gives bare-metal clusters a default
local-storage `StorageClass` backed by node-local host paths, without requiring a dedicated ZFS pool
(see [`zfs-localpv`](../zfs-localpv) for the ZFS-backed alternative).

## Key values / KubeAid-specific configuration

Upstream values live under the `localpv-provisioner:` key.

- `localpv.basePath: "/var/openebs/local"` (`values.yaml`) — the host directory each provisioned volume gets a
  subdirectory under.

## Operational notes

- Data locality is per-node: a pod using a `localpv-provisioner` volume is pinned to whichever node the volume was
  provisioned on. Prefer this for workloads that tolerate node loss (or replicate at the application layer) —
  for anything needing real redundancy on bare metal, use Rook Ceph instead.

## Docs links

- Upstream chart: <https://github.com/openebs/dynamic-localpv-provisioner>
- OpenEBS docs: <https://openebs.io/docs>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
