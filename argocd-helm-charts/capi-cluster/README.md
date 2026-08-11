# CAPI (Core Cluster API)

This chart will setup kubernetes cluster with cluster-api with request provider

## Setup

Install the [cluster-api chart](../cluster-api/)

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

## TODO

* Add support for private repo to get added in bootstrap setup
