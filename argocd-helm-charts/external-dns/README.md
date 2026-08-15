# External DNS

[ExternalDNS](https://github.com/kubernetes-sigs/external-dns) synchronizes exposed Kubernetes Services and
Ingresses with a DNS provider (Cloudflare, Route53, etc.), so DNS records are created/updated automatically instead
of by hand.

## Why it's in KubeAid

Ingress/Service hostnames in KubeAid-managed clusters need matching DNS records; ExternalDNS keeps those in sync
with the cluster's actual state instead of requiring a manual DNS change per deploy.

## Key values

- `policy: sync` — ExternalDNS may create *and delete* records (values.yaml default). Set to `upsert-only` if you
  don't want it deleting records.
- `txtPrefix: _owner.` — ownership TXT records are prefixed, not suffixed.
- `serviceMonitor.enabled: true` — scraped by Prometheus.

## Configuring external-dns with Cloudflare

1. Login to cloudflare.

2. Select "my account" in the right corner. Select api tokens in the left menu.

3. Create a token with the rights: Zone:Read, DNS:Edit - limited to the domains it applies to.

4. You can possibly also correctly create subzones (e.g. az1.abc.com) - and then only give access to it.
   so all sites for that cluster must be under az1.kilroy.eu (e.g. argocd.az1.abc.com etc.)

5. Each cluster should preferably not be able to overlap in the dns names they can create themselves.

NB. Do NOT share this token across multple clusters - instead issue one per cluster.
so you can revoke per cluster and also see which cluster is doing what in cloudflare.

## Operational notes

### Upgrading external-dns chart

The chart previously pinned the upstream `external-dns` subchart to `0.14.0` because `0.14.2` had a CRD-sync issue
([kubernetes-sigs/external-dns#4488](https://github.com/kubernetes-sigs/external-dns/pull/4488)). That has since
been resolved upstream — `Chart.yaml` now tracks a current release. Check `Chart.yaml` for the exact pinned version
before upgrading, and re-check open upstream CRD-sync issues if you're jumping several minor versions at once.

## Docs

- [Upstream ExternalDNS chart README](./charts/external-dns/README.md) — full values reference.
