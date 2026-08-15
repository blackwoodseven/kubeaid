# Cilium Host-Firewall Policy

KubeAid ships a `CiliumClusterwideNetworkPolicy` that locks down the host endpoint on every node.
Enable it on **bare-metal clusters** where the public NIC needs an ingress filter; leave it **disabled
on cloud clusters** that rely on cloud-provider security groups instead.

## Overview

When enabled, the policy:

- Allows cluster-internal traffic by Cilium identity (node-to-node etcd/kubelet, pods, apiserver,
  health probes, localhost)
- Allows admin SSH only from specified CIDRs
- Restricts the Kubernetes API server (port 6443) to explicit source CIDRs (the node public IPs -
  never the open internet)
- Allows HTTP (80) and HTTPS (443) plus ICMP from the world

The policy is **disabled by default**. There is no standalone `kubeaid-cli cluster lockdown`
subcommand; you enable it by setting `hostNetworkPolicy.enabled: true` in your per-cluster Cilium
values overlay (see Configuration below) and rolling it out via ArgoCD.

## Configuration

Set the following values in your per-cluster Cilium values overlay:

```yaml
hostNetworkPolicy:
  enabled: false                # Set to true to activate the host-firewall
  allowSshFrom: []              # CIDRs or bare IPs (treated as /32); empty = SSH open to world
  publicPorts: [80, 443]        # Service ports allowed from the world
  apiserverSourceCIDRs: []      # CIDRs/IPs allowed to reach 6443/TCP; empty = no 6443 rule emitted
```

### Example: Bare-Metal Production Cluster

```yaml
hostNetworkPolicy:
  enabled: true
  allowSshFrom:
    - "203.0.113.0/24"          # Office VPN
    - "198.51.100.42"           # Jump host (treated as /32)
  publicPorts: [80, 443]
  apiserverSourceCIDRs:
    - "203.0.113.0/24"          # Office VPN
    - "10.0.0.0/8"              # Internal network
```

## When to Enable

| Cluster Type | Enable? | Reason |
| ------------ | ------- | ------ |
| Bare Metal | ✅ Yes | No cloud security group; the NIC is directly exposed |
| Hetzner Hybrid | ✅ Yes | Bare-metal workers have exposed NICs |
| HCloud-only | ❌ No | Hetzner Cloud firewall / security groups handle this |
| AWS / Azure | ❌ No | Cloud-provider security groups handle this |

## How It Works

The policy is templated at
[cilium/templates/host-firewall-policy.yaml](../../argocd-helm-charts/cilium/templates/host-firewall-policy.yaml)
and creates a `CiliumClusterwideNetworkPolicy` targeting the host endpoint. Traffic not matching any
allow rule is **dropped** by default (Cilium's host-firewall operates in default-deny mode when a policy
is attached to the host endpoint).

## Enabling After Pivot

After the cluster is bootstrapped and the management cluster has pivoted to the workload cluster,
apply the same `hostNetworkPolicy.enabled: true` values change and let ArgoCD sync it. Note that
`kubeaid-cli`'s interactive config prompt separately exposes a `lockdown` field that gets rendered
into the generated `cluster.lockdown` setting — that's unrelated config plumbing, not a trigger for
this policy.

## See Also

- [Cloud Providers](../hosting/cloud-providers.md) - provider-specific setup
- [Bare Metal](../hosting/bare-metal.md) - SSH-based provisioning
- [Cilium documentation: Host Firewall](https://docs.cilium.io/en/stable/security/host-firewall/)
