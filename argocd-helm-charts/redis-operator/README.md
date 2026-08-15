# Redis-Operator

## Summary

Wraps the [OT-CONTAINER-KIT redis-operator](https://github.com/OT-CONTAINER-KIT/redis-operator) chart, used to
manage redis instances.

It has Custom Resource named:

- Redis
- RediCluster
- RedisSentinel
- RedisReplication.

To support HA in every scenerio.

You need to apply the above CRDs via server-side apply to avoid huge metadata annotations,

## Why it's in KubeAid

Apps deployed onto a KubeAid cluster that need a cache or a small HA Redis/Sentinel/Cluster deployment can
get one via CRD instead of everyone hand-rolling their own StatefulSet + Sentinel wiring.

## Key values

Chart-level toggle in `argocd-helm-charts/redis-operator/values.yaml`:

- `certmanager.enabled: false` — only relevant if `webhook: true` (the `masterSlaveAntiAffinity` webhook,
  off by default upstream). Kept `false` here so, if the webhook is ever turned on, the operator falls back
  to a self-signed cert instead of requiring cert-manager.

### upstream status

Project is active.
