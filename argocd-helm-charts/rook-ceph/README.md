# rook-ceph

## Debugging: See Ceph status

To see rook-ceph status look at the live manifest for the kubernetes resource CephCluster/rook-ceph
under "status:" it should say "HEALTH_OK" or there is something wrong.
To see exactly what is wrong first look at pods with `kubectl -n rook-ceph get pods`
If all pods are OK, then look in ceph-tools with

```shell
    kubectl -n rook-ceph exec -it rook-ceph-tools-<pod-name> -- bash
    # This would give the status of the cluster
    ceph status
```

If that doesnt work you can use the rook-ceph kubectl plugin
`kubectl rook-ceph ceph status`

- Look into alert handling for [CephOSDDiskUnavailable.md](https://gitlab.enableit.dk/obmondo/wiki/-/blobrook-ceph/procedures/alerts/CephOSDDiskUnavailable.md)
    for more debug information.

## CephX key rotation

Rotating CephX keys can take every worker node down at once, so this chart ships with
rotation disabled and one prior key retained.

Kernel mounts are why. `krbd` and `kcephfs` hold the key they mapped with and never
pick up a new one. Once the ticket expires and the prior key is gone, the mount fails
authentication (`mauth authentication failed: -13`), `libceph` retries forever, and
every process touching that volume blocks in uninterruptible D state. The node then
goes `NotReady` with `Ready=Unknown` — never `Ready=False` — SSH stops working, and
nothing is logged because the kernel itself is healthy. Only a reboot clears it.
Processes stuck this way cannot be killed, so RBD images stay mapped,
`VolumeAttachment` objects never clear, and rescheduled pods fail with Multi-Attach.

Defaults set in `values.yaml`:

| Setting | Value | Applies to | Why |
| --- | --- | --- | --- |
| `keyRotationPolicy` | `Disabled` | all three | rotation must be a deliberate act, never a side effect of an upgrade |
| `keyType` | `aes256k` | all three | replaces the `aes` cipher Ceph 20.2.4 flags as insecure — see the node requirement below |
| `keepPriorKeyCountMax` | `1` | **`csi` only** | the old key stays valid while mounts migrate |

`keepPriorKeyCountMax` exists only under `csi` in the CephCluster CRD — `daemon` and
`rbdMirrorPeer` accept `keyGeneration`, `keyRotationPolicy` and `keyType` only. Setting
it there is silently pruned by the API server and leaves the ArgoCD app permanently
OutOfSync.

That asymmetry is deliberate on Rook's part rather than an oversight: only the `csi`
keys are handed to the **in-kernel** clients (`krbd`, `kcephfs`), which hold the key
they mapped with and cannot re-key without a reboot. Daemon keys are used by Ceph's own
processes, which Rook restarts as it rotates them, so they need no grace period.

### Rotating

1. Confirm `csi.keepPriorKeyCountMax` is at least `1` **before** bumping
   `keyGeneration`. With it unset, Rook deletes the old key immediately and every
   mounted volume on every node hangs at once. Check the live cluster, not just git —
   `status.cephx.csi.priorKeyCount` is what Rook actually applied.
2. Bump `keyGeneration` and let Rook issue the new keys. Existing mounts keep working
   on the retained prior key.
3. **Cordon and reboot** the workers one at a time, waiting for `active+clean` between
   each. A reboot is the only thing that re-keys a live kernel mount.
4. Only after every node has been cycled, drop the prior key.

Do **not** `kubectl drain`. The D-state process holding the volume prevents the kernel
from unmapping the RBD, so the `VolumeAttachment` never clears and the evicted pod
fails Multi-Attach on whatever node it lands on — down until the original node reboots
anyway. Draining starts the outage earlier and leaves pods scattered for the next
reboot to disturb again. Cordon stops new scheduling; the reboot does the rest.

### keyType and the Ubuntu 26.04 requirement

Ceph 20.2.4 flags the long-standing `aes` cipher as insecure — that warning is what
prompts most people to rotate in the first place. This chart pins **`aes256k`** so the
cipher is a deliberate choice rather than whatever a Ceph upgrade happens to default
to; an unpinned `keyType` means an upgrade can re-key the cluster unattended, which
behaves exactly like an unplanned rotation.

**`aes256k` requires Linux kernel 7.0 or newer — Ubuntu 26.04 and up.**

That requirement applies to **`csi.keyType` only**. Those keys are consumed by the
in-kernel clients (`krbd`, `kcephfs`), so every node that mounts a Ceph volume has to
be able to use the cipher. `daemon` and `rbdMirrorPeer` keys are only ever used by
userspace Ceph daemons and carry no kernel dependency.

So on a cluster whose nodes are older than Ubuntu 26.04, override just that one:

```yaml
rook-ceph-cluster:
  cephClusterSpec:
    security:
      cephx:
        csi:
          keyType: aes
```

`aes` keeps working on any kernel, at the cost of `AUTH_INSECURE_CLIENT_KEY_TYPE` in
`ceph status` and needing `mon_auth_allow_insecure_key: true` for the mons to accept
and create such keys. Adding a pre-26.04 node to an `aes256k` cluster later will strand
that node's mounts with no obvious explanation, so treat the node OS floor as part of
the cluster's contract.

Change `keyType` and `keyGeneration` in separate steps, and verify the deployed
ceph-csi can actually use the new cipher before rolling it out to every node. A failure
here breaks new attachments (`rados: ret=-22`) while the existing ones are already
hung, and rebooting will not help because the replacement mount cannot be made either.

### Clearing AUTH_EMERGENCY_CIPHERS_SET

Ceph 20.2.4 raises `AUTH_EMERGENCY_CIPHERS_SET` — *"Monitors are configured to use
emergency allowed ciphers"*. This is Rook's **default**, not leftover from an incident:
with `security.cephx.allowedCiphers` unset, Rook enables every cipher by passing
`mon_auth_emergency_allowed_ciphers=aes,aes256k` on the mon command line.

That means it does not appear in `ceph config dump` and `ceph config rm` cannot remove
it. The source is `cmdline`:

```shell
ceph config show mon.<id> | grep -i ciph
```

To clear it, restrict the ciphers in the cluster's values:

```yaml
    security:
      cephx:
        allowedCiphers:
          - aes256k
```

Rook then sets `auth_allowed_ciphers` and stops passing the emergency flag. It is a
command-line argument, so the mons roll one at a time to pick it up.

**Verify every key first.** The CRD warns that this setting "can disrupt cluster
availability", and it means it: restricting the list locks out any entity still holding
a key of an excluded cipher — including `mon.` and `client.admin`, which costs you the
cluster with no way back in, since `ceph config` lives in the mon store.

`status.cephx` cannot answer this. A missing `keyType` there means Rook never recorded
one, **not** that the key is insecure. Compare key lengths instead — an `aes` key is
visibly shorter than an `aes256k` one:

```shell
ceph auth ls -f json | jq -r '.auth_dump[].entity' | while read -r e; do
  printf '%-38s %s\n' "$e" "$(ceph auth get-key "$e" 2>/dev/null | wc -c)"
done
```

Every entity reporting the same length means nothing would be locked out. That includes
the retained prior-generation keys (`<entity>.N`), which `keepPriorKeyCountMax` keeps
alive and which are equally capable of stranding a mount that still authenticates with
one.

This chart deliberately leaves `allowedCiphers` unset. Setting it cluster-wide would
contradict the `csi.keyType: aes` override above — clusters below Ubuntu 26.04 need the
`aes` cipher allowed — so it belongs in per-cluster values, once that cluster has been
verified fully migrated.

## About upstream charts

This includes both of the two upstream rook-ceph charts listed here
`https://rook.io/docs/rook/v1.10/Helm-Charts/helm-charts/`

The upstream chart called "rook-ceph" contains the CRDs and operator (rook)
which watches for Ceph CRs
The upstream chart called "rook-ceph-cluster" contains the Ceph CRs
that make rook setup Ceph on a cluster
