# Ingress-NGINX

[Ingress-NGINX](https://github.com/kubernetes/ingress-nginx) is the Kubernetes community's ingress controller,
using NGINX as reverse proxy and load balancer for Ingress resources.

## Why it's in KubeAid

KubeAid's default ingress controller is [Traefik](../traefik) — that is what `kubeaid-cli` deploys when it
provisions a cluster. Ingress-NGINX is offered as an **alternative** for teams standardised on NGINX (its config
snippets, annotation ecosystem, or existing runbooks). It is not deployed by default; add an Argo CD Application
for it in your kubeaid-config repo if you want it.

Upstream chart: [`ingress-nginx`](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx)
(chart 4.15.1 / controller v1.15.1 pinned here).

## Key values / KubeAid-specific configuration

This wrapper is a pure version pin: `values.yaml` is empty and there are no extra templates, so upstream defaults
apply unchanged. Configure it entirely from your kubeaid-config values file, nested under the `ingress-nginx:`
key:

```yaml
ingress-nginx:
  controller:
    service:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

See the vendored chart's own README under `charts/ingress-nginx/` for the full value reference.

## Operational notes

- The controller Service is `type: LoadBalancer`; on bare-metal clusters without a cloud LB, hand it an address
  via Cilium LB-IPAM — the [`cilium`](../cilium) wrapper's `loadBalancerIPPool` value.
- If you run it alongside Traefik, keep each controller on its own `IngressClass` so they don't compete for the
  same Ingress resources.

## Docs links

- Upstream: <https://kubernetes.github.io/ingress-nginx/>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
