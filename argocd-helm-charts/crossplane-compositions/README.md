# Crossplane Compositions

Obmondo-authored chart (no vendored upstream `charts/` - the compositions are KubeAid's own) that installs
Crossplane `CompositeResourceDefinition`s (XRDs) and `Composition`s defining KubeAid's Azure infrastructure
APIs, plus the `ProviderConfig` those compositions authenticate through.

## Why it's in KubeAid

CAPZ-provisioned (self-managed) Azure clusters need supporting Azure infrastructure that ClusterAPI does not
provision itself: a storage account for the OIDC/workload-identity issuer, managed identities and role
assignments for CAPZ and Azure Service Operator, and (optionally) a Velero backup identity and blob
containers for disaster recovery. This chart turns those into two composite APIs cluster operators apply as
plain Kubernetes claims. See [Azure hosting](../../docs/hosting/cloud-providers.md#azure).

## Prerequisites

- [`crossplane`](../crossplane) core and [`crossplane-providers-and-functions`](../crossplane-providers-and-functions)
  (with `azure.enable: true`) installed first.
- An `azure-credentials` Secret in the release namespace, referenced by the `ProviderConfig` this chart
  installs.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `azure.enable` | Install the `azure` sub-chart (XRDs + Compositions) | `false` |
| `azure.compositions.workloadIdentityInfrastructure.enable` | Install the `WorkloadIdentityInfrastructure` composition | `true` |
| `azure.compositions.disasterRecoveryInfrastructure.enable` | Install the `DisasterRecoveryInfrastructure` composition | `false` |

### `WorkloadIdentityInfrastructure` claim (`azure.kubeaid.org/v1alpha1`)

Given `subscriptionID`, `clusterName`, `location`, `aadApplicationPrincipalID`, and `storageAccountName`,
provisions: a `ResourceGroup`, a Blob storage `Account` + `oidc-provider` `Container` (the OIDC issuer for
workload identity), a `capi` `UserAssignedIdentity` with a `Contributor` role assignment, and federated
identity credentials for both CAPZ (`capz-manager`) and Azure Service Operator
(`azureserviceoperator-default`).

### `DisasterRecoveryInfrastructure` claim (`azure.kubeaid.org/v1alpha1`)

Given `subscriptionID`, `clusterName`, `location`, and `storageAccountName`, provisions: `velero-backups` and
`sealed-secrets-backups` blob `Container`s, a `velero` `UserAssignedIdentity` with a `Storage Blob Data
Owner` role assignment, and a federated identity credential for the `velero` ServiceAccount.

## Operational notes

- Both compositions use `mode: Pipeline` with the `go-templating`, `patch-and-transform`, and `auto-ready`
  functions from `crossplane-providers-and-functions`.
- `defaultCompositionUpdatePolicy: Manual` on both XRDs - composition changes require an explicit revision
  bump on existing claims, they are not applied automatically.
- Deletion policy on the `ResourceGroup` and storage `Account`/`Container` resources is `Orphan`.

## Docs links

- [Crossplane compositions](https://docs.crossplane.io/latest/concepts/compositions/)
- [Azure hosting (CAPZ + Crossplane)](../../docs/hosting/cloud-providers.md)
- Related: [`crossplane`](../crossplane), [`crossplane-providers-and-functions`](../crossplane-providers-and-functions)
