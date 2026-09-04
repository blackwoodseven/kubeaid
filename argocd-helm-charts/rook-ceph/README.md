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

Defaults set in `values.yaml`, applied to `csi`, `daemon` and `rbdMirrorPeer` alike:

| Setting | Value | Why |
| --- | --- | --- |
| `keyRotationPolicy` | `Disabled` | rotation must be a deliberate act, never a side effect of an upgrade |
| `keepPriorKeyCountMax` | `1` | the old key stays valid while mounts migrate |
| `keyType` | *not set* | depends on the cluster — see below |

Set `keepPriorKeyCountMax` on **every** entity, not just `csi`. Rook reports each one
separately under `status.cephx`; anything showing `keyGeneration` without a
`priorKeyCount` has no grace period and will strand on the next rotation.

### Rotating

1. Confirm `keepPriorKeyCountMax` is at least `1` on every entity **before** bumping
   `keyGeneration`. With it unset, Rook deletes the old key immediately and every
   mounted volume on every node hangs at once.
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

### Choosing keyType

Ceph 20.2.4 flags the long-standing `aes` cipher as insecure, which is what prompts
most people to rotate in the first place. Neither value is right for every cluster,
which is why this chart does not pin one:

- **`aes`** works with any kernel, but on Ceph 20.2.4+ it raises
  `AUTH_INSECURE_CLIENT_KEY_TYPE` and needs `mon_auth_allow_insecure_key: true` for the
  mons to accept and create such keys.
- **`aes256k`** clears the warning but requires **kernel 7.0+ on every node** and a
  ceph-csi new enough to handle it. Add a node on an older kernel later and its mounts
  fail with no obvious explanation.

Whichever you pick, pin it explicitly per cluster. Leaving it unset means a Ceph
upgrade can move the default underneath you, and the resulting re-key behaves exactly
like an unplanned rotation. Change `keyType` and `keyGeneration` in separate steps, and
verify the deployed ceph-csi can actually use the new type before rolling it out to
every node — a failure here breaks new attachments (`rados: ret=-22`) while existing
ones are already hung, and rebooting will not help because the replacement mount cannot
be made either.

## About upstream charts

This includes both of the two upstream rook-ceph charts listed here
`https://rook.io/docs/rook/v1.10/Helm-Charts/helm-charts/`

The upstream chart called "rook-ceph" contains the CRDs and operator (rook)
which watches for Ceph CRs
The upstream chart called "rook-ceph-cluster" contains the Ceph CRs
that make rook setup Ceph on a cluster
