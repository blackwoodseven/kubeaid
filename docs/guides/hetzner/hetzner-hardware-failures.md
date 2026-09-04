# Hetzner Hardware Failures Found During Installation

KubeAid checks every disk before it writes anything and refuses a server that fails. On used or
reprovisioned hardware this is often the first time anyone has looked closely at those disks, so the
install is where existing faults surface. Expect some servers to be rejected. That is the check
doing its job.

Two guards run before the OS is written.

**CheckDisk** runs a fio sequential read against each root device and fails the host if throughput
falls below 19 MiB/s on a rotational disk or 39 MiB/s on an SSD or NVMe. It also reads SMART and
fails on attributes marked marginal.

**DetectLinuxOnAnotherDisk** refuses any disk that already holds an LVM physical volume, so an
install cannot quietly destroy a system that is still in use. Set `wipeDisks: true` only once you
are certain the disks hold nothing you want. Check what is on them first; a server that has been
sitting in an account for years may still be running something.

## Reading a CheckDisk failure

The failure message carries the measured numbers for each disk. Read them before deciding anything.

```text
OK: 0x5000c50064380823 (/dev/sdd, HDD): read bandwidth 175 MiB/s
OK: 0x50014ee004244859 (/dev/sdb, HDD): read bandwidth 138 MiB/s
check-disk failed!
  Please note the following marginal Attributes:
  190 Airflow_Temperature_Cel  FLAG 0x0022  VALUE 071  WORST 043  THRESH 045  Old_age  In_the_past
```

Both disks cleared the 19 MiB/s rotational floor by roughly nine times. The host failed on a SMART
attribute whose worst recorded value once dipped below its threshold, flagged `In_the_past`. That is
a temperature excursion somewhere in the drive's history, not a fault now. A failure shaped like
this is usually safe to accept.

Throughput below the floor is a different message and a different decision.

```text
FAIL: 0x50014ee003ef574e (/dev/sda, HDD): read bandwidth 15 MiB/s is below threshold 19 MiB/s
FAIL: 0x50014ee2b3f91845 (/dev/sdb, HDD): read bandwidth  5 MiB/s is below threshold 19 MiB/s
```

Treat one reading like this with suspicion rather than certainty. A disk still busy finishing a
previous install can measure slow once and pass cleanly on the next run. The same pair of drives
read 15 and 5 MiB/s on one attempt and passed on the next. A disk that fails across several runs is
failing.

## Accepting a disk you have judged healthy

CheckDisk records its verdict as a permanent error, so the host stays rejected until you clear it.
Two annotations, on the management cluster:

```bash
kubectl -n capi-cluster annotate hetznerbaremetalhost <server-id> \
  capi.syself.com/ignore-check-disk=true --overwrite
kubectl -n capi-cluster annotate hetznerbaremetalhost <server-id> \
  capi.syself.com/permanent-error-
```

The latch lives on the custom resource, so it does not survive into a new management cluster. A
fresh bootstrap re-runs the checks and you apply these again.

To skip the check for a machine permanently rather than per-cluster, CAPH also reads
`skipCheckDisk` on the `HetznerBareMetalMachine`. The KubeAid chart does not expose it today.

## A server that installs and then never returns

The harder case is a server where installimage reports success and the machine never comes back.
Nothing in the install log says `ERROR`, because writing the disk succeeded. Whether the firmware
can boot what was written is not something installimage checks.

Work through it in this order.

Check whether the machine answers at all. If it responds to ICMP but not on port 22, it booted
something and is not serving SSH. If it answers neither, it is not up.

Boot it into rescue. Rescue is a network boot and does not touch the disks, so it separates the two
causes cleanly. A machine that comes up in rescue has working hardware and a boot problem on disk. A
machine that will not come up in rescue after a hardware reset has a problem below that, and more
resets will not tell you anything new.

Two things about rescue that cost time if you do not know them. The arming lasts 60 minutes and is
consumed by the next boot, so the reboot after that goes back to the installed system. And
activating rescue does not reboot the server; you have to trigger the reset yourself.

Use the console when the first two steps disagree or run out. Hetzner's vKVM boots from the same
rescue menu and shows the screen, which is the only way to tell a stalled POST from a bootloader
prompt from a failed network boot. Everything short of the console is inference from outside the
machine.

Open a support ticket once the console shows a stalled POST, a black screen, or a disk the firmware
cannot see. Repeated hardware resets diagnose nothing on their own, and a dedicated-server hardware
ticket raised early is usually answered the same day.
