# hcloud-fip-controller

Wrapper chart for [cbeneke/hcloud-fip-controller](https://github.com/cbeneke/hcloud-fip-controller).

It keeps a Hetzner Cloud **Floating IP** attached to the active (leader-elected)
node, so a `hostNetwork` workload that must be reachable at a fixed public IP —
e.g. NetBird **Coturn** (STUN/TURN, UDP 3478 / 5349 + the 49152–65535 relay
range, which an LB can't front) — survives node failures: the leader pod assigns
the Floating IP to its own node, and when that node dies a new leader reassigns
it (lease-based, ~15s failover by default).

## Operator responsibilities

This chart deploys the controller only. Two things must be arranged outside it:

1. **`floatingIPs`** + **`existingSecretName`** — set per-cluster in the values
   overlay. `existingSecretName` must point to a Secret carrying an
   `HCLOUD_API_TOKEN` key (use a kubeaid SealedSecret; don't inline the token via
   `hcloudApiToken`).
2. **Node networking** — the controller only moves the API *assignment*; it does
   **not** configure the node's interface. The Floating IP must already be bound
   on every candidate node's NIC via cloud-init / netplan, or the node won't
   answer for it once the IP lands there.

## Notes

- For real HA, spread the 3 replicas across nodes (podAntiAffinity / topology
  spread) so leader election can fail over when a node dies.
- Land the workload it protects (e.g. Coturn) on a **dedicated worker**, not a
  control-plane node — a public 16k-port UDP relay does not belong next to
  etcd/apiserver.
