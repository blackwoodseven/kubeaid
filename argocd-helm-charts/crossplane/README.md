# Crossplane

Wrapper around the upstream [Crossplane](https://www.crossplane.io) Helm chart (v2.3.4). Crossplane extends
the Kubernetes API with CRDs that represent external cloud infrastructure, and reconciles them the same way
Kubernetes reconciles Pods and Deployments.

This chart installs the Crossplane core (controller manager + RBAC manager) only. Cloud-specific providers,
functions, and compositions ship as separate KubeAid charts:

- [`crossplane-providers-and-functions`](../crossplane-providers-and-functions) - installs `Provider` and
  `Function` packages
- [`crossplane-compositions`](../crossplane-compositions) - installs the `CompositeResourceDefinition`s and
  `Composition`s that define KubeAid's own infrastructure APIs

## Why it's in KubeAid

On Azure, KubeAid provisions self-managed (CAPZ) clusters with ClusterAPI. CAPZ and its supporting services
(Velero for disaster recovery, workload identity for federated credentials) need Azure infrastructure -
resource groups, storage accounts, managed identities, role assignments - that ClusterAPI itself does not
provision. Crossplane fills that gap declaratively, inside the same GitOps/ArgoCD flow as the rest of the
cluster. See [Azure hosting](../../docs/hosting/cloud-providers.md#azure).

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `crossplane.resourcesCrossplane.limits.cpu` | CPU limit for the `crossplane` container | `null` (unset upstream default) |
| `crossplane.resourcesRBACManager.limits.cpu` | CPU limit for the RBAC manager container | `null` (unset upstream default) |

Both overrides remove the upstream CPU limit; only memory remains capped.

## Docs links

- [Crossplane docs](https://docs.crossplane.io)
- Upstream chart README: [`charts/crossplane/README.md`](./charts/crossplane/README.md)
- [Azure hosting (CAPZ + Crossplane)](../../docs/hosting/cloud-providers.md)
- Related: [`crossplane-providers-and-functions`](../crossplane-providers-and-functions),
  [`crossplane-compositions`](../crossplane-compositions)
