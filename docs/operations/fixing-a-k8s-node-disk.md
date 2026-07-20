# Procedure to fix a faulty disk in a kubernetes node

This guide is written while handling a corrupted NVMe disks in one of our managed kubernetes bare-metal node.

ssh into the node and check:

```shell
root@<server-name> ~ # zpool status
  pool: primary
 state: DEGRADED
status: One or more devices has been removed by the administrator.
 Sufficient replicas exist for the pool to continue functioning in a
 degraded state.
action: Online the device using zpool online' or replace the device with
 'zpool replace'.
  scan: scrub repaired 0B in 00:05:33 with 0 errors on Sun Jun 14 00:29:34 2026
config:

 NAME                                                STATE     READ WRITE CKSUM
 primary                                             DEGRADED     0     0     0
   mirror-0                                          DEGRADED     0     0     0
     nvme-SAMSUNG_MZVL2512HCJQ-00B00_SERIAL-NUMBER  ONLINE       0     0     0
     nvme-SAMSUNG_MZVL2512HCJQ-00B00_SERIAL-NUMBER  REMOVED      0     0     0
```

Procedure:

1. Cordon and drain the node, check etcd health, and manage rook ceph if it's running on your node
2. Fix/Request cloud provider for disk change
3. After fixes/changes, replace the disk in zpool with newer one or fixed one and unset ceph settings and recheck etcd health

## Phase 1: Before taking the node down

### 1. Check etcd health (all members)

```sh
kubectl -n kube-system get pods -l component=etcd -o wide

kubectl -n kube-system exec etcd-<healthy-node> -- etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health --cluster
```

Please note: With one control plane node down in a 3 control plane node cluster, etcd runs 2/3, quorum holds but
there is zero fault tolerance, so all members must be healthy before you start.

### 2. Check Ceph health and OSD layout (If installed & running on the node)

```sh
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health detail
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd tree
```

You need HEALTH_OK (or an understood warning), and you need to know which OSDs / mons / MDS live on the node,
pools must be able to tolerate losing that host for some time

### 3. Set the Ceph noout flag (If installed & running on the node)

Ref - <https://docs.ceph.com/en/latest/rados/troubleshooting/troubleshooting-osd/#stopping-without-rebalancing>

```sh
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd set noout
```

Ceph usually tries to rebalance OSDs if it detects some OSDs are down and since this entire work is intentional,
we should disable rebalancing temporarily

### 4. Confirm rook won't auto-remove the OSDs (If installed & running on the node)

This step is a safety measure, so ceph do not go rogue while the node is down

```sh
kubectl -n rook-ceph get cephcluster -o jsonpath='{.items[0].spec.removeOSDsIfOutAndSafeToRemove}'
# must be false or empty
```

### 5. dry-run drain for verification

```sh
kubectl drain node-name \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=120 \
  --timeout=10m \
  --dry-run=client
```

Please also take care of any ```PodDisruptionBudget``` related blocks.

### 6. Cordon and Drain after verification

```sh
kubectl drain node-name \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=120 \
  --timeout=10m
```

It evicts all regular workloads so they reschedule elsewhere; DaemonSets and static pods (etcd, apiserver) remain,
which is expected.

### 7. Confirm the planned degraded state

```sh
kubectl get nodes            # NODE = NotReady,SchedulingDisabled
# etcd: 2/3 healthy (step 1 command)
# ceph: 2 osds down, noout set, PGs degraded but all active
```

This is the expected state for the whole window, so alerts are expected to come up.

### Rules during the maintenance window

- Do NOT touch the other control plane nodes (etcd has zero fault tolerance).
- Do NOT restart other OSDs or change Ceph config (PGs have no spare copies).
- Silence Ceph/node alerts for the window.

---

## Phase 2: Get the disk changed via cloud provider

### 1. Identify the disks by serial, never by device name

```sh
lsblk -o NAME,MODEL,SERIAL
```

`/dev/nvme0n1` vs `nvme1n1` can swap between boots, serials never lie. The surviving disk has ZFS partitions;
the new one is blank.

### 2. Wipe the new disk to make sure no residue are present

```sh
wipefs -a /dev/<new-disk>
blkdiscard -f /dev/<new-disk>
```

It clears any leftover signatures from burn-in/refurb and TRIMs the SSD to a factory-clean state, double-check
the serial before running.

### 3. Reboot into the normal OS and Replace the dead ZFS mirror member (on the node)

```sh
zpool status <pool>
ls -l /dev/disk/by-id/ | grep <new-serial>

zpool replace <pool> \
  <old-disk-by-id-name> \
  /dev/disk/by-id/<new-disk-by-id-name>

zpool status -v <pool>    # use this command to keep monitoring the progress
```

### 2. Verify etcd is back to 3/3

```sh
# same endpoint health --cluster command as Phase 1 step 1
```

### 3. Uncordon the node

```sh
kubectl uncordon $NODE
```

### 4. Watch Ceph recover (if ceph installed on the node)

```sh
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status
# wait for: 8/8 osds up, all PGs active+clean, 0% degraded
```

### 5. Unset noout, only after all PGs are active+clean (if ceph installed on the node)

Please make sure ```ceph status``` goes back to 0% degradation. it may take 3 to 4 hours sometimes so you need to wait

```sh
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph osd unset noout
```

### 6. Final verification

Confirm every layer. nodes, Ceph, ZFS, workloads is fully back before you close the ticket.

```sh
kubectl get nodes                                    # all Ready, none SchedulingDisabled
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph status    # HEALTH_OK
zpool status <pool>                                  # ONLINE, 0 errors
kubectl get pods -A | grep -vE 'Running|Completed'   # nothing stuck
```
