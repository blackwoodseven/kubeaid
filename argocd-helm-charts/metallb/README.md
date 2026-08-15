# MetalLB

[MetalLB](https://metallb.universe.tf/) is a load-balancer implementation for bare-metal Kubernetes
clusters. It gives `Service` objects of type `LoadBalancer` a real, externally reachable IP on
clusters that don't run on a cloud provider with a built-in load-balancer integration, by announcing
addresses via Layer 2 (ARP/NDP) or BGP.

This wrapper (chart version 0.11.0) pins the Bitnami `metallb` chart (currently `6.4.22`, from
`https://charts.bitnami.com/bitnami`) and adds the `IPAddressPool` / `L2Advertisement` CRs KubeAid
needs to hand out addresses.

## Why it's in KubeAid

Bare-metal and Hetzner-style KubeAid clusters have no cloud load-balancer to satisfy `type:
LoadBalancer` Services (ingress-nginx/Traefik entrypoints, etc.). MetalLB fills that gap.

## Prerequisites

- Kubernetes 1.23+, Helm 3.8.0+ (upstream chart requirement).
- A block of IPs routable to the cluster's nodes for Layer 2 mode, or a BGP route reflector/peer for
  BGP mode.

## Key values / KubeAid-specific configuration

- `values.yaml` in this wrapper ships empty — all Bitnami `metallb` subchart configuration and the
  address pool below are expected to come from a cluster's own values file.
- `ipaddresspool.name` / `ipaddresspool.addresses` — rendered into an `IPAddressPool`
  (`templates/ipaddresspool.yaml`); `addresses` accepts a list of CIDRs or explicit start-end IP
  ranges.
- `ipaddresspool.layer` (truthy) — when set, renders an `L2Advertisement`
  (`templates/layer.yaml`) named `l2advertisement1` advertising the pool above over Layer 2. Leave
  unset for BGP-only setups.

## Docs links

- Upstream chart: <https://github.com/bitnami/charts/tree/main/bitnami/metallb>
- MetalLB docs: <https://metallb.universe.tf/>
- Address pools / L2 configuration: <https://metallb.universe.tf/configuration/>
