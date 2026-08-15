# Reloader

Reloader can watch changes in ConfigMap and Secret and do rolling upgrades on Pods with their associated
DeploymentConfigs, Deployments, Daemonsets Statefulsets and Rollouts.

Upstream: https://github.com/stakater/Reloader

## Why it's in KubeAid

Without it, a ConfigMap/Secret edit (e.g. rotated credentials, updated config) sits inert until something
else bounces the pods. Reloader closes that gap cluster-wide, so app teams don't have to wire their own
restart-on-config-change logic per Deployment.

## Key values

Chart wraps the upstream `reloader` subchart (`argocd-helm-charts/reloader/values.yaml`):

- `reloader.reloader.watchGlobally: true` — watches ConfigMaps/Secrets across all namespaces, not just its own.
- `reloader.reloader.reloadOnCreate: true` — also triggers on resource creation, not just updates.
- `reloader.reloader.serviceMonitor.enabled: true` — Reloader's own metrics get scraped by Prometheus.
- `deployment.containerSecurityContext` — runs with all capabilities dropped, no privilege escalation,
  read-only root filesystem, and the `RuntimeDefault` seccomp profile.

## How to use Reloader

For a Deployment called foo have a ConfigMap called foo-configmap or Secret called foo-secret or both.
Then add your annotation (by default reloader.stakater.com/auto) to main metadata of your Deployment.

```shell
kind: Deployment
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
spec:
  template:
    metadata:
```

This will discover deploymentconfigs/deployments/daemonsets/statefulset/rollouts automatically where
foo-configmap or foo-secret is being used either via environment variable or from volume mount.
And it will perform rolling upgrade on related pods when foo-configmap or foo-secretare updated.

![Refer](https://github.com/stakater/Reloader)
