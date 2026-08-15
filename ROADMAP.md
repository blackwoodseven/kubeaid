# Roadmap

High-level feature goals for KubeAid. The current implementation status of
each item — what's done, what's in progress, and how it works — is documented
in [Technical Details on the
Features](./docs/kubeaid/features-technical-details.md).

This roadmap reflects current priorities and will shift as the project and
its users grow; it isn't a committed release schedule.

## Feature goals

* Set up Kubernetes clusters on:
  * **Physical servers**: On-premise and [Hetzner](https://www.hetzner.com/) Bare Metal
  * **Cloud VMs**: [Hetzner HCloud](https://www.hetzner.com/cloud), [AWS](https://aws.amazon.com/), and
    [Azure](https://azure.microsoft.com/)
  * **Managed control planes**: [AWS EKS](https://aws.amazon.com/eks/) and
    [Azure AKS](https://azure.microsoft.com/en-us/products/kubernetes-service)
  * **Hybrid clusters**: Combining Hetzner Bare Metal with HCloud VMs
* Auto-scaling for all cloud Kubernetes clusters and easy scaling for physical
  servers
* Manage an ever-growing list of open-source Kubernetes applications (see the
  [`argocd-helm-charts/`](./argocd-helm-charts/) folder for the current list)
* Build advanced, customised Prometheus monitoring using just a per-cluster
  config file, with automated handling of trivial alerts, like disk filling
* GitOps setup — ALL changes in a cluster are done via Git, AND we detect if
  anyone adds anything in the cluster or modifies existing resources without
  doing it through Git
* Frequent updates for KubeAid-managed applications with security and bug
  fixes, ready to be issued to your cluster(s) at will — so you can focus on
  your business applications
* [Air-gapped operation](https://kubernetes.io/blog/2023/10/12/bootstrap-an-air-gapped-cluster-with-kubeadm/)
  of your clusters, to ensure operational stability
* Cluster security — proper NetworkPolicies to secure intra-cluster and
  ingress traffic, ensuring least privilege between applications
* Backup, recovery and live migration of applications or entire clusters
* Major cluster upgrades via a shadow Kubernetes setup (a parallel failover
  cluster that allows you to test upgrades and seamlessly switch over),
  utilising the recovery and live migration features
* Supply-chain attack protection and discovery, with frequent security scans
  of all software used in the clusters (as new vulnerabilities are constantly
  being discovered)

## Contributing to the roadmap

Have a use case this doesn't cover, or want to work on one of the items
above? Open an [issue](https://github.com/Obmondo/KubeAid/issues) — see
[CONTRIBUTING.md](./CONTRIBUTING.md) for how to get started.
