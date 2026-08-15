# AWS EBS CSI Driver

Wrapper chart for the upstream [`aws-ebs-csi-driver`](https://github.com/kubernetes-sigs/aws-ebs-csi-driver) chart
(pinned to `2.63.1`, appVersion `1.63.1`), the CSI driver that provisions AWS **EBS** volumes as
`PersistentVolume`s.

## Why it's in KubeAid

EKS clusters install no storage driver by default, so `kubeaid-cli` renders this chart only for **EKS** clusters
(`AWSEKSSpecificNonSecretTemplateNames`) to provide a default `StorageClass`. Self-managed (CAPI) AWS clusters run
`ccm-aws` instead and are not currently wired to this chart by `kubeaid-cli`.

## Prerequisites

- The identity the controller runs under (the EKS node instance profile, or IRSA once wired) needs EBS permissions
  — the AWS-managed `AmazonEBSCSIDriverPolicy` covers this.

## Key values / KubeAid-specific configuration

Upstream values live under the `aws-ebs-csi-driver:` key.

- `controller.revisionHistoryLimit` / `node.revisionHistoryLimit`: `0` — no old ReplicaSets/DaemonSet revisions
  kept around (`values.yaml`).
- On EKS, `kubeaid-cli` additionally renders a default `gp3` `StorageClass`
  (`storageclass.kubernetes.io/is-default-class: "true"`, `volumeBindingMode: WaitForFirstConsumer`,
  `allowVolumeExpansion: true`, `parameters.encrypted: "true"`) via the values overlay.
- `templates/netpol-aws-ebs-csi-driver.yaml` renders a Calico-flavored `crd.projectcalico.org/v1` `NetworkPolicy`
  when `networkpolicies: true` is set (not set by default in this chart's `values.yaml`). It also allows egress to
  `kube2iam` (port 8181) — a legacy IAM-via-annotations pattern this chart predates IRSA with; treat it as
  historical unless you're still running kube2iam.

## Docs links

- Upstream chart: <https://github.com/kubernetes-sigs/aws-ebs-csi-driver/tree/master/charts/aws-ebs-csi-driver>
- Upstream project: <https://github.com/kubernetes-sigs/aws-ebs-csi-driver>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
