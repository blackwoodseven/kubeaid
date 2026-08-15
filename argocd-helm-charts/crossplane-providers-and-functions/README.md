# Crossplane Providers and Functions

Obmondo-authored chart (no vendored `charts/` subchart from upstream - only local `templates/`) that
installs Crossplane `Provider` and `Function` packages on top of the [`crossplane`](../crossplane) core.

## Why it's in KubeAid

`crossplane-compositions` defines the composite resources KubeAid uses to provision Azure infrastructure for
self-managed (CAPZ) clusters; those compositions can only run once the matching providers and pipeline
functions are installed. This chart is the install step for those packages.

## Prerequisites

- [`crossplane`](../crossplane) core installed in the cluster.
- An `azure-credentials` Secret (Service Principal credentials) in the release namespace - referenced by the
  `ProviderConfig` shipped in `crossplane-compositions`.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `azure.enable` | Install the `azure` sub-chart (Azure `Provider` packages) | `false` |

Cluster-agnostic `Function` packages (`templates/functions.yaml`) are always installed, independent of
`azure.enable`:

| Function | Package |
|---|---|
| `patch-and-transform` | `xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:v0.9.0` |
| `go-templating` | `xpkg.crossplane.io/crossplane-contrib/function-go-templating:v0.10.0` |
| `auto-ready` | `xpkg.crossplane.io/crossplane-contrib/function-auto-ready:v0.5.0` |

### `azure` sub-chart (`charts/azure`)

Installs five Azure `Provider` packages: `azure-network`, `azure-storage`, `azure-managed-identity`,
`azure-ad`, `azure-authorization` (all `crossplane-contrib` upbound-family providers). The network provider
also pulls in `crossplane-contrib-provider-family-azure`, which handles Azure authentication for the whole
provider family.

## Docs links

- [Crossplane providers](https://docs.crossplane.io/latest/concepts/providers/)
- [Crossplane functions](https://docs.crossplane.io/latest/concepts/composition-functions/)
- [Azure hosting (CAPZ + Crossplane)](../../docs/hosting/cloud-providers.md)
- Related: [`crossplane`](../crossplane), [`crossplane-compositions`](../crossplane-compositions)
