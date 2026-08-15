# CCM Hetzner

Wrapper chart for the upstream [`hcloud-cloud-controller-manager`](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
chart (dependency aliased to `ccm-hetzner`, pinned to `1.34.0`). Per the chart description, this **replaces the
legacy `syself/hetzner-cloud-controller-manager` fork** — upstream gained Hetzner **Robot** (bare-metal) support
and forwards kubelet's `--node-ip` to `InternalIP` as of `v1.24.0`, which the syself fork never did.

## Why it's in KubeAid

This one chart directory backs **two** distinct Argo CD Applications on Hetzner clusters, differentiated only by
values file and `nameOverride`:

- **`ccm-hetzner`** — rendered for **bare-metal** and **hybrid** modes
  (`HetznerCCMNonSecretTemplateNames`). Owns Hetzner **Robot** (bare-metal) node lifecycle; in hybrid mode its
  controllers are scoped to `cloud-node,cloud-node-lifecycle` so it doesn't fight `ccm-hcloud` over Services.
- **`ccm-hcloud`** — rendered for **hcloud** and **hybrid** modes (`HCloudCCMNonSecretTemplateNames`). Owns
  HCloud node routing/InternalIP and all HCloud `LoadBalancer` reconciliation.

In a hybrid cluster both run simultaneously in `kube-system`, each scoped to its own node population.

## Prerequisites

- `HCLOUD_TOKEN` / `ROBOT_USER` / `ROBOT_PASSWORD` from the `kube-system/cloud-credentials` Secret that
  `kubeaid-cli` provisions (`pkg/core/hcloud_credentials.go`) — this chart's `values.yaml` points every
  `secretKeyRef` at that Secret's `hcloud` / `robot-user` / `robot-password` keys (overriding the upstream
  chart's own `hcloud`/`token` default naming so the existing Secret works unmodified).

## Key values / KubeAid-specific configuration

Upstream values live under the `ccm-hetzner:` key.

- `nameOverride: ccm-hetzner` — matches the syself-era resource name so an in-place chart switch replaces the
  existing Deployment/ServiceAccount instead of leaving two CCMs racing for ownership of `node.status`.
- `robot.enabled` — gates Robot (bare-metal) support; `kubeaid-cli`'s overlay sets it `true` for bare-metal/hybrid
  and `false` otherwise (upstream defaults it to `true`).
- `networking.enabled` (default `false`) — HCloud private-network pod routing; `kubeaid-cli` flips this on via
  `--set` in hybrid mode (HCloud CPs reaching bare-metal workers over the private network).
- `env.HCLOUD_TOKEN` / `ROBOT_USER` / `ROBOT_PASSWORD` / `networking.network` — wired to `cloud-credentials`
  as above (`robot-user`/`robot-password` marked `optional: true`).
- `nodeSelector: node-role.kubernetes.io/control-plane: ""` — runs on control-plane nodes only.
- For the `ccm-hcloud` instance specifically: `nameOverride: ccm-hcloud`, `robot.enabled: false`,
  `env.HCLOUD_LOAD_BALANCERS_NETWORK_ZONE`, and conditionally `HCLOUD_LOAD_BALANCERS_DISABLE_PUBLIC_NETWORK` /
  `HCLOUD_LOAD_BALANCERS_USE_PRIVATE_IP` depending on cluster topology (workload-behind-VPN, private nodes).

## Operational notes

- Both instances mirror the `node.kubernetes.io/not-ready:Exists:NoSchedule` toleration the bootstrap `postKubeadm`
  step sets, so Argo CD's desired state matches and doesn't strip it on the next sync — CCM itself must be able to
  schedule before it clears `node.cloudprovider.kubernetes.io/uninitialized`.
- Switching from the syself fork: the old `ccm-hetzner` → `cluster-admin` ClusterRoleBinding is orphaned until
  Argo CD prunes it (bootstrap-time `kubectl apply` won't remove it). Acceptable short-term — the orphan grants
  the same ServiceAccount, so there's no auth regression in the gap.

## Docs links

- Upstream project: <https://github.com/hetznercloud/hcloud-cloud-controller-manager>
- Upstream Helm repo: <https://charts.hetzner.cloud>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
