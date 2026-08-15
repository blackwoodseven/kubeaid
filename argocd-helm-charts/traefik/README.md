# Traefik

[Traefik](https://traefik.io/traefik/) is a cloud-native reverse proxy and ingress controller. It watches
Kubernetes Ingress resources (and its own `IngressRoute` CRDs) and routes external traffic to Services.

## Why it's in KubeAid

Traefik is the **default ingress controller** on KubeAid clusters: `kubeaid-cli` renders a `traefik` Argo CD
Application (plus an optional `traefik-internal` instance) for every cluster it provisions.
[`ingress-nginx`](../ingress-nginx) is available as an alternative if you prefer NGINX. TLS certificates come
from the sibling `cert-manager` chart.

Upstream chart: [`traefik`](https://github.com/traefik/traefik-helm-chart) (v41.2.0 pinned here).

## Key values / KubeAid-specific configuration

Upstream values live under the `traefik:` key. KubeAid defaults (`values.yaml`):

- `ports.web` permanently redirects HTTP to HTTPS; `ports.websecure` has TLS enabled.
- **PROXY protocol is enabled on both entrypoints** (`additionalArguments`), so Traefik sees real client IPs
  behind a load balancer. The LB must actually send PROXY protocol — e.g. on Hetzner Cloud the Service needs
  `load-balancer.hetzner.cloud/uses-proxyprotocol: "true"`, otherwise every connection is rejected.
- `providers.kubernetesIngress.publishedService.enabled: true` — populates Ingress `status.loadBalancer`, without
  which Argo CD apps behind Traefik stay stuck in `Progressing`.
- 2 replicas, PodDisruptionBudget (`maxUnavailable: 1`), Prometheus `ServiceMonitor` enabled,
  `instanceLabelOverride: traefik`.

KubeAid-specific keys rendered from this wrapper's `templates/`:

- `wildcardCertificates` — cert-manager `Certificate`s for wildcard domains (each must start with `*.`), issued
  by the ClusterIssuer named in `wildcardCertificates.issuer`.
- `ipwhitelists` — a map of name → CIDR list, rendered as Traefik `ipWhiteList` Middlewares.
- `middleware.jwt` — an opt-in JWT-validation Middleware (requires `middleware.jwt.public_key`).

Per-cluster override via kubeaid-config, e.g. an internal-only load balancer:

```yaml
traefik:
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
```

The equivalent annotations on AKS/Azure:

```yaml
service:
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"   # internal LB
    # or, for an internet-facing LB:
    # service.beta.kubernetes.io/azure-load-balancer-internal: "false"
    # service.beta.kubernetes.io/azure-load-balancer-resource-group: <your-resource-group-name>
```

and on AWS for an internet-facing (rather than internal) load balancer:

```yaml
service:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
```

## Operational notes

- Several Traefik resources drift from the rendered state at runtime (Service `clusterIP`, Deployment checksum
  annotations, ClusterRole rules, dashboard IngressRoute, PDB). Add `ignoreDifferences` to the Argo CD
  Application — see [examples/argocd-application-ignore-drift.yaml](examples/argocd-application-ignore-drift.yaml).
- Running multiple Traefik instances requires binding each to its own ingress class with
  `--providers.kubernetesingress.ingressclass=<class>`, or they fight over Ingress status updates.
- The dashboard is not exposed by default; reach it with
  `kubectl -n traefik port-forward <pod> 9000:9000` → `http://localhost:9000/dashboard/`.
- Traefik has a default limit on request body size that can affect file uploads; reconfigure it with a
  middleware — see [examples/request-body-middleware.yaml](examples/request-body-middleware.yaml).

### Client certificate (mTLS) auth

Docs: <https://doc.traefik.io/traefik/https/tls/#client-authentication-mtls>. The CA cert Secret's key must be
named `ca.crt` or `tls.ca`:

```sh
kubectl create secret generic internalca-cert --namespace traefik --dry-run=client --from-file=/path/to/ca.crt -o yaml | kubeseal --controller-namespace system --controller-name sealed-secrets -o yaml
```

Then reference it from `tlsOptions` in values:

```yaml
tlsOptions:
  tls-client-auth:
    clientAuth:
      clientAuthType: VerifyClientCertIfGiven
      secretNames:
        - internalca-cert
```

## Docs links

- Upstream chart: <https://github.com/traefik/traefik-helm-chart>; docs: <https://doc.traefik.io/traefik/>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
