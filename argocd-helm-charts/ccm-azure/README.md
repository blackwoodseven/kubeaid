# CCM Azure

Wrapper chart for the upstream
[`cloud-provider-azure`](https://github.com/kubernetes-sigs/cloud-provider-azure) chart (pinned to `1.36.0`), the
Azure cloud-controller-manager that initialises node metadata (providerID, InternalIP, zone labels) and reconciles
`LoadBalancer` Services against Azure Load Balancer.

## Why it's in KubeAid

Rendered for **self-managed (CAPZ) Azure clusters** — `AzureSpecificNonSecretTemplateNames` in `kubeaid-cli`,
alongside `azuredisk-csi-driver`, `azure-workload-identity-webhook`, Crossplane, and Cluster Autoscaler. **AKS**
clusters skip it: `AzureAKSSpecificNonSecretTemplateNames` is empty, since AKS runs the cloud controller itself.

## Key values / KubeAid-specific configuration

This wrapper's own `values.yaml` is empty. `kubeaid-cli`'s values overlay sets, under `cloud-provider-azure:`:

- `infra.clusterName` — the cluster's name, so CCM scopes/tags Azure resources (Load Balancers, etc.) it manages
  to this cluster.

## Docs links

- Upstream project: <https://github.com/kubernetes-sigs/cloud-provider-azure>
- Upstream Helm repo: <https://raw.githubusercontent.com/kubernetes-sigs/cloud-provider-azure/master/helm/repo>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
