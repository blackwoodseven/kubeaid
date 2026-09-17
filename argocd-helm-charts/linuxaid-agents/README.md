# linuxaid-agents

Runs the LinuxAid OpenVox (Puppet) agent on every Kubernetes node, so the node OS —
packages, SSH keys, sudo, hardening — is managed the same way LinuxAid manages ordinary
servers. Cluster API builds the cluster but leaves the node OS unmanaged; this closes
that day-2 gap without running a second config-management stack.

## How it works

```
operator Deployment            one Job per node              on the node
(unprivileged)                 (privileged, ephemeral)
      |                                |                          |
      | every `interval`:              |                          |
      |  list nodes  ----------------->|                          |
      |  create Job per node           | stage the binaries ----->| /opt/obmondo/bin
      |    201 -> new run              | install client cert ---->| puppet SSL tree
      |    409 -> still running, skip  | linuxaid-install ------->| openvox agent, if missing
      |                                | clone control-repo ----->| /opt/obmondo/openvox
      |                                | nsenter into host -------> puppet apply
```

Three properties worth knowing:

- **No static node list.** Nodes are discovered each cycle, so a newly joined node is
  managed on the next pass with no chart change.
- **The 409 *is* the lock.** Job names are deterministic per node, so a node whose Job is
  still running simply conflicts and is skipped. No leader election, no stored state —
  which is why the operator only needs `create` on jobs, never `get`/`list`/`delete`.
- **Privilege is short-lived.** The operator itself is unprivileged; only the per-node
  Jobs are privileged, and they exit and are reaped by `ttlSecondsAfterFinished`.

The pod is only a delivery shell: it stages the static `linuxaid-cli` and `linuxaid-install`
binaries and the client cert onto the host, then `nsenter`s into the host's namespaces —
package and user management must happen on the host, not in a container. There,
`linuxaid-install --masterless` installs the OpenVox agent if it is missing and writes a
server-less `puppet.conf`, and `linuxaid-cli run-openvox --apply` runs `puppet apply`.

## Hiera

The `hiera` values are the node's hiera data. They are rendered verbatim into a ConfigMap,
mounted into each Job at `/hiera-data`, staged onto the host, and read by `puppet apply` as
the **global** layer — so chart values beat control-repo defaults.

```yaml
hiera:
  classes:
    - role::kubeaid
  common::monitor::prometheus::server: prometheus.demo.example.com
```

`controlRepo.ref` is additionally recorded as `common::system::openvox::environment`, so the
puppet code can tell which control-repo tag it was applied from.

## Prerequisites

- The `obmondo-clientcert` secret (`tls.crt` / `tls.key` / `ca.crt`) in the release
  namespace. The cert is pre-signed — nodes enroll nothing.
- That namespace must permit privileged pods (PSA), since the per-node Jobs are privileged.
- Pull access to `ghcr.io/obmondo`, where both images are public and published with every
  linuxaid-cli release.

## Values

| Key | Default | Purpose |
| --- | --- | --- |
| `operator.image.repository` | `ghcr.io/obmondo/linuxaid-agent` | Operator image. |
| `agentImage.repository` | `ghcr.io/obmondo/linuxaid-cli` | Per-node agent image. |
| `operator.image.tag`, `agentImage.tag` | `v1.11.2` | linuxaid-cli release; keep both on the same one. |
| `certname` | `""` | CN of the obmondo-clientcert, shared by all nodes. **Required** — the operator exits if unset. |
| `enforce` | `false` | `false` = report-only (`puppet --noop`); `true` = apply changes. |
| `interval` | `4h` | How often the operator reconciles one Job per node. |
| `controlRepo.url` | Obmondo linuxaid | Control-repo cloned onto each node. |
| `controlRepo.ref` | `""` | Tag to check out; empty = the repo's latest tag. |
| `controlRepo.secretName` | `""` | Secret with `ssh-privatekey` or `token` for a private repo. |
| `obmondoClientCert.secretName` | `obmondo-clientcert` | Secret the Jobs mount. |
| `openvoxEnvironment` | `master` | OpenVox environment applied. |
| `nodeSelector` | `""` | Label selector; empty = all nodes. |
| `agentJob.*` | | `ttlSecondsAfterFinished`, `activeDeadlineSeconds`, `backoffLimit`. |
| `hiera` | `{}` | Free-form hiera data for every node. |

## Caveats

All nodes share one certname, so they share one puppet identity. That suits a uniform node
role but rules out per-node reporting. Start with `enforce: false` and flip it only once
runs report clean.
