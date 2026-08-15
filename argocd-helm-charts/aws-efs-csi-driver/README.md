# AWS EFS CSI Driver

Wrapper chart for the upstream [`aws-efs-csi-driver`](https://github.com/kubernetes-sigs/aws-efs-csi-driver) chart
(pinned to `4.4.1`, appVersion `3.4.1`), the CSI driver that provisions AWS **EFS** (NFS-backed, `ReadWriteMany`)
volumes as `PersistentVolume`s.

## Why it's in KubeAid

Not currently rendered by `kubeaid-cli`'s bootstrap flow — there is no `AWS*TemplateNames` entry for it in
`pkg/constants/templates.go`. It's an opt-in chart for AWS clusters that need shared/`ReadWriteMany` storage (EBS
is block storage, single-attach); enable it manually as an Argo CD Application the same way other
`argocd-helm-charts/` charts are wired in.

## Prerequisites

- An EFS filesystem and access point(s) provisioned out-of-band (Terraform/Crossplane/console).
- IAM permissions for the driver identity to call the EFS API (mount targets, access points).

## Key values / KubeAid-specific configuration

Upstream values live under the `aws-efs-csi-driver:` key.

- `replicaCount: 1` (`values.yaml`) — single controller replica.
- `networkpolicies` (default `false`, not present in `values.yaml` but read by the template): when set to `true`,
  `templates/netpol-aws-efs-csi-driver.yaml` renders a Calico-flavored `crd.projectcalico.org/v1` `NetworkPolicy`
  restricting egress to the apiserver and to `kube2iam` (port 8181) — a legacy IAM-via-annotations pattern that
  predates IRSA; treat it as historical unless you're still running kube2iam.

## Operational notes

- `docs/guides/release.md` explicitly excludes `aws-efs-csi-driver` from `manage-helm-chart.sh --update-all`, so
  it does not track upstream automatically the way most other vendored charts do — bump it manually.
- No `StorageClass` is shipped by this wrapper; create one (with a `fileSystemId` parameter, typically
  `provisioningMode: efs-ap` for per-PVC access points) per cluster.

## Docs links

- Upstream chart: <https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/charts/aws-efs-csi-driver>
- Upstream project: <https://github.com/kubernetes-sigs/aws-efs-csi-driver>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
