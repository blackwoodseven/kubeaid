# kubeaid-custom-azure

A small KubeAid-authored chart carrying custom Kubernetes resources for Azure clusters. Today it contains exactly
one resource: the `kubeaid-azurefile-ext4` StorageClass.

## Why it's in KubeAid

Azure's stock Azure Files storage classes mount SMB shares, whose filesystem semantics some workloads cannot use.
This chart was added to give Keycloak's PostgreSQL an ext4-formatted volume on Azure; other apps needing the same
can reference the class by name.

## Key values / KubeAid-specific configuration

`values.yaml` is empty — there is nothing to configure. The rendered StorageClass is:

```yaml
kind: StorageClass
metadata:
  name: kubeaid-azurefile-ext4
provisioner: file.csi.azure.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
parameters:
  skuName: Standard_LRS
  fsType: ext4
```

## Prerequisites

- An Azure cluster with the Azure File CSI driver (`file.csi.azure.com`) installed.

## Docs links

- Azure File CSI driver: <https://github.com/kubernetes-sigs/azurefile-csi-driver>
