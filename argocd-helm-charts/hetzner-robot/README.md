# hetzner-robot

Automatic Kubernetes control-plane endpoint failover on Hetzner bare-metal servers. The chart runs Obmondo's
[failover script](https://github.com/obmondo) (`ghcr.io/obmondo/hetzner-failover-script`) as a single-replica
Deployment pinned to control-plane nodes; on the configured interval it checks the Hetzner Failover IP and, in a
failover scenario, re-points it to a healthy control-plane node via the Hetzner Robot API. This chart is authored
in KubeAid (not a vendored upstream wrapper).

## Why it's in KubeAid

Hetzner bare-metal clusters built by KubeAid can use a Hetzner Failover IP as the Kubernetes API endpoint.
`kubeaid-cli` includes this chart automatically as the `hetzner-robot` Argo CD app (namespace `kube-system`,
sync-order 5) whenever the control plane is on Hetzner Bare Metal and the endpoint is a Failover IP, and sets
`failoverIP` from that endpoint in the generated `values-hetzner-robot.yaml`.

## Prerequisites

- A Secret (default name `cloud-credentials`) in the release namespace with keys `robot-user`, `robot-password`
  (the Hetzner Robot webservice user) and `hcloud` (a Hetzner Cloud API token). KubeAid's cluster bootstrap
  creates it — see [cluster-api-operator/docs/hetzner.md](../cluster-api-operator/docs/hetzner.md).
- A Failover IP ordered on the Robot account, routed to one of the control-plane servers.

## Key values / KubeAid-specific configuration

| Value | Default | Meaning |
|---|---|---|
| `failoverIP` | `""` | The Failover IP to manage. Required — rendering fails when empty. |
| `cloudCredentialsSecretName` | `cloud-credentials` | Secret holding the Robot user/password and hcloud token. |
| `cronTimeInterval` | `5m` | How often the script runs its check. |
| `image.repository` / `image.tag` | `ghcr.io/obmondo/hetzner-failover-script` / `v1.2.0` | Script image. |

## Operational notes

- The pod resolves its own node's public address by `GET`-ing the Node object from the Kubernetes API
  (`status.addresses` → `ExternalIP`), so the chart ships a ServiceAccount with exactly cluster-wide `get` on
  `nodes` — nothing else.
- It is pinned to control-plane nodes (`node-role.kubernetes.io/control-plane` nodeSelector) and tolerates both
  the `control-plane` and legacy `master` `NoSchedule` taints; without the tolerations it would stay Pending.
- After provisioning, verify on the Robot UI that the Failover IP points at the intended node.

## Docs links

- Hetzner cluster setup: [cluster-api-operator/docs/hetzner.md](../cluster-api-operator/docs/hetzner.md)
- Hetzner Failover IP: <https://docs.hetzner.com/robot/dedicated-server/ip/failover/>
