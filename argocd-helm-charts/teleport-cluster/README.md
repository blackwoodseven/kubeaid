# Teleport Cluster

[Teleport](https://goteleport.com) is a unified access plane for infrastructure (SSH, Kubernetes API, databases,
apps). This chart deploys the central Teleport proxy/auth cluster (`clusterName` in values.yaml, e.g.
`teleport.obmondo.com`) that managed clusters join through.

> **Deprecated:** Teleport is no longer KubeAid's default access layer — new clusters use the NetBird mesh with
> Keycloak SSO instead. This chart remains available for existing setups.

## Why it's in KubeAid

KubeAid previously used Teleport as the access layer for managed clusters: instead of distributing raw
kubeconfigs, each managed cluster runs the [`teleport-kube-agent`](../teleport-kube-agent/README.md) chart and
joins this central cluster, so cluster access can be issued/revoked/audited from one place. On current clusters
that role is filled by NetBird (mesh access) and Keycloak (SSO).

## Upgrade

* Check pv is set to `Retain`
* Backup data by taking a shell on the teleport-cluster pod

  ```sh
  tctl get all --with-secrets > state.yaml
  ```

* Copy the backup to local laptop/desktop

  ```sh
  kubectl cp teleport-cluster/teleport-cluster-7dcbdbfc7d-drhg4:/backup.yaml .
  ```

  (`teleport-cluster-7dcbdbfc7d-drhg4` is an example pod name — substitute the actual pod from
  `kubectl get pods -n teleport-cluster`.)

## Docs

- [teleport-kube-agent](../teleport-kube-agent/README.md) — the per-cluster agent that joins this Teleport cluster.
