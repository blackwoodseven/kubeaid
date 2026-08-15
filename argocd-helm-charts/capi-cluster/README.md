# CAPI (Core Cluster API)

This is the chart that renders the actual [Cluster API](https://cluster-api.sigs.k8s.io/) manifests (`Cluster`,
control-plane, and worker `MachineDeployment`/`MachinePool` resources) for a managed cluster — `kubeaid-cli` deploys
it as the `capi-cluster` ArgoCD Application when provisioning or updating a cluster.

## Why it's in KubeAid

KubeAid provisions and manages Kubernetes clusters declaratively via Cluster API. This chart is the per-provider
(Hetzner/AWS/Azure) manifest layer; the [`cluster-api-operator`](../cluster-api-operator/README.md) chart installs
the CAPI core and the provider CRDs/controllers this chart's resources depend on.

## Setup

Install the [cluster-api-operator chart](../cluster-api-operator/README.md) first — it installs the CAPI core and
provider controllers this chart's resources (`Cluster`, `HetznerCluster`, `AWSManagedControlPlane`, etc.) depend on.

[hetzner robot control plane](./examples/hetzner-robot-control-plane.yaml)

## Managed control planes

The AWS and Azure subcharts can provision cloud-managed control planes instead
of self-managed kubeadm ones:

* `aws.eks: true` — EKS via CAPA's `AWSManagedControlPlane`; workers stay
  self-managed MachineDeployments (NodeadmConfig on EKS optimized AL2023
  AMIs). See [values.example.eks.yaml](./charts/aws/values.example.eks.yaml).
* `azure.aks: true` — AKS via CAPZ's `AzureManagedControlPlane`; workers are
  AKS agent pools (`AzureManagedMachinePool`), scaled by AKS's built-in
  autoscaler, with kube-proxy disabled (Cilium replaces it — the
  `KubeProxyConfigurationPreview` feature must be registered on the
  subscription). See
  [values.example.aks.yaml](./charts/azure/values.example.aks.yaml).

Both suites are covered by helm-unittest tests (`charts/aws/tests/`,
`charts/azure/tests/`) — run them with:

```bash
docker run --rm -v $(pwd):/apps helmunittest/helm-unittest charts/aws charts/azure
```
