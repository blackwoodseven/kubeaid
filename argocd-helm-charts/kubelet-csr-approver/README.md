# Kubelet CSR Approver

We support provisioning clusters in `Hetzner`, with the public IPs of the `Hetzner Bare Metal
Servers (HBMS)` disabled.

When a node based on such HBMS joins the Kubernetes cluster, it's `Kubelet` will create a
`Certificate Signing Request (CSR)`. And that CSR will contain the HBMS' **private IP**, that we
assigned.

There is a `CSR approver` baked in `ClusterAPI Provider Hetzner (CAPH)`, which usually is supposed
to approve that CSR. However, instead of approving, CAPH will deny it, since it doesn't know about
the private IP of the HBMS that we've assigned.
> We dont want to patch CAPH, adding support for this.

So, the solution we went for, was : to disable the `CSR approver` baked into CAPH. And, instead,
deploy `Kubelet CSR Approver` to approve the CSR.
