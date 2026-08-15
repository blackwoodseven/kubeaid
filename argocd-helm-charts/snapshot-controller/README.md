# Snapshot Controller

Deploys the [external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter)
`snapshot-controller`, which is what makes `VolumeSnapshotClass` / `VolumeSnapshot` /
`VolumeSnapshotContent` work. It's required for CSI snapshotting and isn't tied to any specific CSI
driver — many Kubernetes distributions bundle it, but not all do.

This wrapper (chart version 1.0.0) pins the Piraeus `snapshot-controller` chart (currently `5.2.0`,
from `https://piraeus.io/helm-charts`) and wires up a self-signed cert-manager `Issuer` for the
controller's webhook.

## Why it's in KubeAid

CSI drivers used across KubeAid clusters (Rook-Ceph, hcloud-csi, EBS/EFS CSI, etc.) rely on the
snapshot CRDs and controller to support snapshotting/restoring PVCs. If a cluster doesn't already
have `volumesnapshotclasses.snapshot.storage.k8s.io` (check with `kubectl get crd
volumesnapshotclasses.snapshot.storage.k8s.io`), it needs this chart.

## Key values / KubeAid-specific configuration

- `networkpolicies: true` (default) — enables `templates/netpol-snapshot-controller.yaml` and
  `templates/netpol-snapshot-validation-webhook.yaml`.
- `snapshot-controller.webhook.tls.certManagerIssuerRef` points the webhook's TLS at the
  `Issuer`/`selfsigned` this chart creates (`templates/Issuer.yaml`, a cert-manager `Issuer` with
  `selfSigned: {}` in the release namespace) rather than requiring a pre-existing issuer.
- `snapshot-controller.webhook.revisionHistoryLimit` / `snapshot-controller.controller.revisionHistoryLimit`
  both set to `0` — no old ReplicaSets retained.

## Operational notes

`VolumeSnapshot`s created by Velero (or similar backup tooling) can outlive the backup they belong
to and keep costing money on the cloud provider's snapshot storage. Periodically check for orphaned
snapshots — see the [Velero chart README](../velero/README.md#troubleshooting) for the cleanup
procedure.

## Docs links

- Upstream chart: <https://github.com/piraeus-datastore/helm-charts/tree/main/charts/snapshot-controller>
- external-snapshotter: <https://github.com/kubernetes-csi/external-snapshotter>
- Kubernetes volume snapshots: <https://kubernetes.io/docs/concepts/storage/volume-snapshots/>
