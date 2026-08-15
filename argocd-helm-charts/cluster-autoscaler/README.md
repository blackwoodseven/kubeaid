# Cluster Autoscaler

[Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) scales
the number of worker nodes up or down to match pending/underutilized pods, by resizing node groups
(ASGs, VMSS, Cluster API `MachineDeployment`/`MachinePool`, etc.) rather than Kubernetes resources.

This wrapper (chart version 1.21.1) pins the upstream `autoscaler/cluster-autoscaler` chart (currently
`9.59.0`, from `https://kubernetes.github.io/autoscaler`) and adds a Cluster API scale-from-zero
`ClusterRole` plus KubeAid network policy templates.

## Why it's in KubeAid

Self-managed KubeAid clusters (CAPA/AWS, CAPZ/Azure, Hetzner via Cluster API) need something to grow
and shrink node pools as workload demand changes. Managed control planes with their own built-in
autoscaler (e.g. Azure AKS) don't use this chart — see
[docs/hosting/cloud-providers.md](../../docs/hosting/cloud-providers.md), which documents AKS/CAPZ
managing agent pools directly instead.

## Prerequisites

- RBAC-enabled Kubernetes 1.10+.
- Cloud credentials/IAM permissions for the target provider (an IAM role via IRSA on AWS, a Service
  Principal on Azure — see the SealedSecret example below).
- The cluster-autoscaler image's major/minor version should track the cluster's Kubernetes
  major/minor version; compatibility isn't verified against mismatched versions.

## Key values / KubeAid-specific configuration

- `clusterAPIScaleFromZeroSupport.enabled` (default `false`) plus one of `.aws` / `.azure` /
  `.hcloud` — when enabled, renders a `ClusterRole` (`templates/clusterrole.yaml`) granting `get`,
  `list`, `watch` on the matching Cluster API infrastructure machine template CRD
  (`awsmachinetemplates`, `azuremachinetemplates`, or `hcloudmachinetemplates`) plus read access to
  `storage.k8s.io` resources (`storageclasses`, `csinodes`, `csidrivers`, `csistoragecapacities`,
  `volumeattachments`). Needed for Cluster Autoscaler to size Cluster API node groups that start at
  zero replicas — see the [Cluster API scale-from-zero
  docs](https://cluster-api.sigs.k8s.io/tasks/automated-machine-management/autoscaling#rbac-changes-for-scaling-from-zero).
- `networkpolicies` is referenced by `templates/netpol-aws-default.yaml` (namespace default-deny +
  DNS egress) and `templates/netpol-autoscaler.yaml` (egress to the AWS API, kube2iam on 8181, and
  the apiserver on 443) but isn't set in this chart's `values.yaml`, so both Calico-flavored
  `NetworkPolicy` templates render as no-ops unless a cluster's values file sets it to `true`.

## Operational notes

- Azure credentials are typically delivered as a SealedSecret of literals (`SubscriptionID`,
  `TenantID`, `ClientID`, `ClientSecret`, `ResourceGroup`, `NodeResourceGroup`, `VMType`,
  `ClusterName`) named `cluster-autoscaler-azure-cluster-autoscaler` in the `cluster-autoscaler`
  namespace:

  ```sh
  kubectl create secret generic cluster-autoscaler-azure-cluster-autoscaler -n cluster-autoscaler \
  --dry-run=client \
   --from-literal=SubscriptionID="jwdmkwd73eke38kjwkkwd" \
   --from-literal=TenantID="klwdmkk79j99i9"  \
   --from-literal=ClientID="keki9ieeennkjimdkwm" \
   --from-literal=ClientSecret="ddkwwkwkdkdmkwmww" \
   --from-literal=ResourceGroup="k8s-prod-az1" \
   --from-literal=NodeResourceGroup="MC_k8s-prod-az1_prod_az1_obmondo_eu_northeurope" \
   --from-literal=VMType="vmss" \
   --from-literal=ClusterName="obmondo" \
   -o yaml | kubeseal --controller-namespace system --controller-name sealed-secrets > cluster-autoscaler.yaml
  ```

  The literal values above are per-cluster and cloud-specific — this template is only valid as-is for Azure.

  The Service Principal itself is created with:

  ```sh
  az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<subscription-id>" --years 4000 --output json
  ```
- With multiple node groups, `--expander` chooses which one to grow: `random`, `most-pods`, or
  `least-waste` (falls back to `random` on a tie).
- If nodes aren't scaling down, check: node group already at its minimum, scale-down-disabled
  annotation, node unneeded for less than `--scale-down-unneeded-time`, a recent scale-up/failed
  scale-down, or `--scale-down-enabled=false`.
- If nodes aren't scaling up, check that the pending pod's requests actually fit some configured
  node group, and that no node group is already at its maximum.

## Docs links

- Upstream chart: <https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler>
- AWS cloud-provider notes: <https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md>
- Troubleshooting FAQ: <https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md>
- [docs/hosting/cloud-providers.md](../../docs/hosting/cloud-providers.md)
