# HCloud CSI Driver

Wrapper chart for the upstream [`hcloud-csi`](https://github.com/hetznercloud/csi-driver) chart (dependency name
`hcloud-csi`, pinned to `2.22.1`), the CSI driver that provisions Hetzner Cloud **Volumes** as
`PersistentVolume`s.

## Why it's in KubeAid

Rendered on **Hetzner HCloud clusters** — `HCloudSpecificNonSecretTemplateNames` in `kubeaid-cli`, covering both
pure-hcloud and hybrid (hcloud + bare-metal) modes. It runs alongside `ccm-hetzner`/`ccm-hcloud` and
`cluster-autoscaler`.

## Prerequisites

- An `HCLOUD_TOKEN` — supplied via the `cloud-credentials` Secret (`hcloud` key), the same SealedSecret
  `ccm-hetzner`/`ccm-hcloud` and `hcloud-fip-controller` read from.

## Key values / KubeAid-specific configuration

This wrapper's own `values.yaml` is empty; `kubeaid-cli`'s values overlay sets, under `hcloud-csi:`:

- `controller.hcloudToken.existingSecret` — `name: cloud-credentials`, `key: hcloud`.
- `controller.nodeSelector` / `node.nodeSelector` — `instance.hetzner.cloud/provided-by: cloud`, so both the
  controller and the node DaemonSet only schedule on HCloud-provisioned nodes, never on bare-metal (Robot) nodes.
- `controller.tolerations` — tolerates `node-role.kubernetes.io/control-plane`, since a hybrid cluster with
  control-plane-only HCloud nodes and bare-metal workers needs the controller to run on the control plane.

## Docs links

- Upstream chart & driver: <https://github.com/hetznercloud/csi-driver>
- Upstream Helm repo: <https://charts.hetzner.cloud>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
