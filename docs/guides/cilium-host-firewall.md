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

The policy is **disabled by default**. After bootstrapping, `kubeaid-cli cluster lockdown` flips it on
during the pivot phase.

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

## Integration with kubeaid-cli

After the cluster is bootstrapped and the management cluster has pivoted to the workload cluster,
run:

```bash
kubeaid-cli cluster lockdown
```

This enables the host-firewall policy along with other post-pivot hardening steps.

## See Also

- [Cloud Providers](../hosting/cloud-providers.md) - provider-specific setup
- [Bare Metal](../hosting/bare-metal.md) - SSH-based provisioning
- [Cilium documentation: Host Firewall](https://docs.cilium.io/en/stable/security/host-firewall/)
