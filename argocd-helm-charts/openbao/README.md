# OpenBao

The upstream [openbao chart](https://github.com/openbao/openbao-helm), with
nothing added. Everything is set per cluster under `openbao:` in the cluster's
values. This README shows how to run it with high availability on Raft,
unsealing with a static key, initialization, Kubernetes auth for clients and
backups. Requires OpenBao 2.6.0 or later.

The examples assume release `openbao` in namespace `openbao`.

## High availability with Raft

Three replicas with integrated (Raft) storage. Each replica keeps a full copy of
the data on its own volume; a write is committed once 2 of 3 have it, so the
cluster survives the loss of one replica. Replicas find each other through
`retry_join`, one block per replica:

```yaml
openbao:
  injector:
    enabled: false
  server:
    ha:
      enabled: true
      replicas: 3
      raft:
        enabled: true
        setNodeId: true
        config: |
          ui = true

          listener "tcp" {
            tls_disable = 1
            address = "[::]:8200"
            cluster_address = "[::]:8201"
          }

          storage "raft" {
            path = "/openbao/data"
            retry_join {
              leader_api_addr = "http://openbao-0.openbao-internal.openbao.svc:8200"
            }
            retry_join {
              leader_api_addr = "http://openbao-1.openbao-internal.openbao.svc:8200"
            }
            retry_join {
              leader_api_addr = "http://openbao-2.openbao-internal.openbao.svc:8200"
            }
          }

          service_registration "kubernetes" {}
    # Keep the data volumes when the StatefulSet is deleted or scaled down
    persistentVolumeClaimRetentionPolicy:
      whenDeleted: Retain
      whenScaled: Retain
  ui:
    enabled: true
    # Only the leader, never a sealed pod
    activeOpenbaoPodOnly: true
    publishNotReadyAddresses: false
```

The upstream chart adds the rest: one replica per node (required pod
anti-affinity), a PodDisruptionBudget that keeps a drain from taking out a
majority, and the `openbao-active` Service that always points at the leader.
Clients should use `openbao-active`: standbys answer reads themselves and can be
slightly behind. The StatefulSet uses `OnDelete`, so a config change reaches a
pod only when the pod is deleted.

## Unsealing with a static key

A replica starts sealed. With the static seal it unseals itself from a key file,
so a restart needs no operator. Create a 32-byte key and deliver it as a
sealed-secret named `openbao-unseal`, with the key file named
`unseal-<key id>.key`:

```sh
openssl rand -out unseal-1.key 32
kubectl create secret generic openbao-unseal -n openbao --dry-run=client -o yaml \
  --from-file=unseal-1.key=unseal-1.key | kubeseal -o yaml > openbao-unseal.yaml
```

Mount it and add the seal to the Raft config above:

```yaml
openbao:
  server:
    volumes:
      - name: openbao-unseal
        secret:
          secretName: openbao-unseal
    volumeMounts:
      - name: openbao-unseal
        mountPath: /openbao/secrets
        readOnly: true
    ha:
      raft:
        config: |
          # ... as above, plus:
          seal "static" {
            current_key_id = "1"
            current_key    = "file:///openbao/secrets/unseal-1.key"
          }
```

- Keep an offline copy of the key. Without it, no snapshot can be restored.
- Anyone holding the key plus a volume or a snapshot can read every secret.
- To rotate: add a new key with a new id, set it as `current_key_id` /
  `current_key` and the old one as `previous_key_id` / `previous_key`, then
  delete the pods one at a time, leader last; the new leader re-wraps the stored
  keys. Drop the old key once no retained snapshot needs it. Never reuse an id.

## Initializing a new cluster

A new cluster starts uninitialized. Initialize it once, either by hand or with
self-initialization.

### By hand

```sh
kubectl -n openbao exec -ti openbao-0 -- bao operator init
```

With the static seal this prints recovery key shares and a root token, and the
replica unseals itself; the others join it. Give the recovery key shares to
their holders and keep them offline: they are needed to generate a new root
token (`bao operator generate-root`) and for static key rotation. Configure
OpenBao with the root token (see [Kubernetes auth](#kubernetes-auth-for-clients)),
then revoke it with `bao token revoke -self`.

### Self-initialization

OpenBao can initialize itself from `initialize` blocks in its config: on first
start it runs them with a root token and revokes that token afterwards, so no
root token or recovery share is ever handed out. It requires an auto-unseal such
as the static seal, and it runs only once, on a new cluster.

```hcl
initialize "recovery-key" {
  request "create-recovery-key" {
    operation = "update"
    path      = "sys/rotate/recovery/init"
    data = {
      secret_shares    = 1
      secret_threshold = 1
    }
  }
}

initialize "kubernetes-auth" {
  request "enable" {
    operation = "update"
    path      = "sys/auth/kubernetes"
    data = {
      type = "kubernetes"
    }
  }
  request "configure" {
    operation = "update"
    path      = "auth/kubernetes/config"
    data = {
      kubernetes_host = "https://kubernetes.default.svc"
    }
  }
}
```

Add a request that leaves you a way in, e.g. an admin policy and a Kubernetes
auth role or an OIDC method, or nobody can log in once the root token is
revoked. The recovery key above lets static key rotation work; its share is not
returned.

Bootstrap with one replica, because OpenBao runs `retry_join` and
self-initialization at the same time: a replica whose join is still in flight
would initialize a second cluster. So:

1. Set `server.ha.replicas: 1` and add the `initialize` blocks to the Raft
   config. Sync and wait until `openbao-0` is ready.
2. Remove the `initialize` blocks and set `replicas: 3`. Sync; the new replicas
   join `openbao-0`.

If a request fails on the first start, the server refuses to start again until
its volume is wiped, so try changes to these blocks on a throwaway cluster. Do
not run the first start with `trace` logging, which logs every request and
response.

## Kubernetes auth for clients

Workloads log in with their own service account token: OpenBao checks it with
Kubernetes (TokenReview, using its own service account, which the upstream chart
binds to `system:auth-delegator`) and returns an OpenBao token with the role's
policies. Give each client a projected token with its own audience, and do not
mount the default Kubernetes API token:

```yaml
spec:
  serviceAccountName: my-app
  automountServiceAccountToken: false
  containers:
    - name: app
      volumeMounts:
        - name: openbao-token
          mountPath: /var/run/secrets/openbao
          readOnly: true
  volumes:
    - name: openbao-token
      projected:
        sources:
          - serviceAccountToken:
              audience: openbao-my-app
              expirationSeconds: 600
              path: token
```

The role binds the service account, its namespace and the audience to
policies:

```sh
bao write auth/kubernetes/role/my-app \
  bound_service_account_names=my-app \
  bound_service_account_namespaces=my-namespace \
  audience=openbao-my-app \
  token_policies=my-app token_ttl=10m
```

The client logs in with
`bao write auth/kubernetes/login role=my-app jwt=@/var/run/secrets/openbao/token`.
A token with another audience is refused, so two containers sharing one service
account can still get separate roles by mounting tokens with different
audiences, each only in its own container.

## Backup

Raft snapshots, taken online by the upstream chart's backup CronJob
(`snapshotAgent`) and uploaded to S3. A snapshot is atomic and holds everything:
secrets, policies, auth config and tokens. Volume-level backups (Velero, CSI
snapshots) are not valid backups, because each volume is captured separately
while Raft is writing; exclude these volumes from Velero.

```yaml
openbao:
  snapshotAgent:
    enabled: true
    schedule: "0 * * * *"
    # Secret with AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    s3CredentialsSecret: openbao-s3
    config:
      s3Host: s3.example.com
      # Same as s3Host, so s3cmd uses path-style URLs
      s3Bucket: s3.example.com
      s3Uri: s3://openbao-backups
      # Snapshots older than this are deleted after each upload
      s3ExpireDays: "14"
      baoAuthPath: kubernetes
      baoRole: snapshot
      tokenPath: /var/run/secrets/openbao/token
    extraVolumes:
      - name: openbao-token
        projected:
          sources:
            - serviceAccountToken:
                audience: openbao-snapshot
                expirationSeconds: 600
                path: token
    extraVolumeMounts:
      - name: openbao-token
        mountPath: /var/run/secrets/openbao
        readOnly: true
```

The bucket must live outside the cluster, and the credentials need delete as
well as write. Create the policy and role the CronJob logs in with:

```sh
bao policy write snapshot - <<EOF
path "sys/storage/raft/snapshot" {
  capabilities = ["read"]
}
EOF
bao write auth/kubernetes/role/snapshot \
  bound_service_account_names=openbao-snapshot \
  bound_service_account_namespaces=openbao \
  audience=openbao-snapshot token_policies=snapshot token_ttl=10m
```

## Restore

A restore replaces the whole cluster state with a snapshot. Run it as a
maintenance window.

1. Every replica must run with the static key that was current when the
   snapshot was taken, as the current or previous key. `-force` skips this
   check, but a replica restarted afterwards stays sealed with `unknown key id`
   until that key is added.
2. Download the snapshot and, with a token allowed to `update`
   `sys/storage/raft/snapshot`, run `bao operator raft snapshot restore <file>`.
   This works on the same cluster and on a freshly initialized one.
3. Tokens issued after the snapshot are gone and clients log in again; tokens
   that existed at snapshot time come back if not expired, even if revoked
   since. Policies, roles and auth methods revert to the snapshot.
