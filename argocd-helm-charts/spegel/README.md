# Spegel

Wrapper around the upstream [Spegel](https://github.com/spegel-org/spegel) Helm chart (v0.7.4). Spegel runs as a
DaemonSet and turns the nodes into a cluster-local, peer-to-peer image mirror: when a node pulls an image, it fetches
the layers from other nodes that already have them, and only goes to the upstream registry when no node does.

## Why it's in KubeAid

Faster image pulls and less traffic to upstream registries (and their rate limits), most noticeably when new nodes
join or a new image rolls out across many nodes.

## Prerequisites

See the upstream [getting started](https://spegel.dev/docs/getting-started/) guide for the exact containerd config
and per-distribution notes.

## Key values / KubeAid-specific configuration

`values.yaml` is empty, so the upstream defaults apply. Settings go under `spegel:` (the dependency name); Spegel's
own options sit under a second `spegel:` key inside it.

| Value | Description | Default |
|---|---|---|
| `spegel.spegel.mirroredRegistries` | Registries to mirror; empty mirrors all of them | `[]` |
| `spegel.spegel.containerdRegistryConfigPath` | Must match containerd's `config_path` | `/etc/containerd/certs.d` |
| `spegel.spegel.prependExisting` | Keep existing mirror configuration on the node and prepend Spegel's | `false` |
| `spegel.serviceMonitor.enabled` | Create a ServiceMonitor for kube-prometheus | `false` |
| `spegel.grafanaDashboard.enabled` | Create a Grafana dashboard | `false` |
| `spegel.resources` | Requests/limits | 128Mi memory request and limit |


## Docs links

- [spegel-org/spegel](https://github.com/spegel-org/spegel)
- [Getting started](https://spegel.dev/docs/getting-started/)
