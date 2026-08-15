# Azure Disk CSI Driver

Wrapper chart for the upstream [`azuredisk-csi-driver`](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
chart (pinned to `1.34.4`, appVersion `1.34.4`), the CSI driver that provisions Azure **Managed Disk** volumes as
`PersistentVolume`s.

## Why it's in KubeAid

Rendered for **self-managed (CAPZ) Azure clusters** — `AzureSpecificNonSecretTemplateNames` in `kubeaid-cli`.
**AKS** clusters skip it entirely: AKS already runs its own Azure Disk CSI driver, CSI snapshot controller, and
`StorageClass`es, so `AzureAKSSpecificNonSecretTemplateNames` is empty and no azure-specific storage/CCM addon is
rendered on AKS beyond the common set.

## Prerequisites

- Runs alongside `ccm-azure` and `azure-workload-identity-webhook` on self-managed clusters; the node identity
  (UAMI / service principal) needs the Azure Disk data-plane role.

## Key values / KubeAid-specific configuration

This wrapper's own `values.yaml` is empty — no KubeAid-level overrides on top of the upstream chart's defaults.
Override the `azuredisk-csi-driver:` key from the cluster's values overlay as needed.

## Docs links

- Upstream chart: <https://github.com/kubernetes-sigs/azuredisk-csi-driver/tree/master/charts>
- Upstream project: <https://github.com/kubernetes-sigs/azuredisk-csi-driver>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
