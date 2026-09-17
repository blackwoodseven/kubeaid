# Pod Autoscaling with KEDA

[KEDA](https://keda.sh) is a Kubernetes event-driven autoscaler. It provides the `external.metrics.k8s.io` API and
drives `ScaledObject`/HPA autoscaling from Prometheus queries, CPU/memory, queues, and other event sources.

## Why it's in KubeAid

KubeAid also supports autoscaling via `kube-prometheus`'s Prometheus Adapter (`custom.metrics.k8s.io`) — see
[Pod Autoscaling Guide](../../docs/operations/monitoring/pod-autoscaling.md). KEDA is the recommended path for new
setups: rules live in a `ScaledObject` instead of jsonnet Prometheus Adapter rules, which is much easier to reason
about.

**NOTE: Do not combine KEDA's autoscaling (described in this guide) with Kubernetes HPA + Prometheus Adapter for the
same pod deployment. They will compete with each other and break things.**

**NOTE2: This assumes your cluster is setup with KubeAid because it provides sane defaults, although it's possible
to set this up on non-KubeAid clusters too.**

## Introduction & Situation

- Your application (running on K8s via a `Deployment` of pods) exposes metrics on an http endpoint.
- There is a `Service` for that deployment.
- There is a `ServiceMonitor` (K8s resource) for that service that tells Prometheus that it needs to scrape metrics
  from that service.

## Setup Prerequisites

Set `connect_keda: true` in your kubeaid managed cluster's prometheus build jsonnet vars file
`(kubeaid-config/k8s/<clustername>/<clustername>-vars.jsonnet)`.

Regenerate kube prometheus YAML with

```sh
kubeaid/build/kube-prometheus/build.sh /path/to/kubeaid-config/k8s/<clustername>
```

(the argument is the cluster directory containing `<clustername>-vars.jsonnet`, not the jsonnet file itself). This
generates YAML that includes the network policy allowing KEDA to connect to Prometheus.

Enable the chart via your `kubeaid-config` repo's override pattern (an ArgoCD Application in
`argocd-apps/templates/`, with cluster-specific values sourced from `argocd-apps/values-keda.yaml`):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: keda
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  project: kubeaid
  sources:
    - repoURL: https://github.com/Obmondo/KubeAid.git
      path: argocd-helm-charts/keda
      targetRevision: HEAD
      helm:
        valueFiles:
          - $values/k8s/<cluster>/argocd-apps/values-keda.yaml
    - repoURL: <your-config-repo>
      targetRevision: HEAD
      ref: values
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
```

Create `values-keda.yaml` in your cluster config repo (can be empty to start with default chart values).

Commit the changes to your cluster config repo and sync.

KEDA provides the `external.metrics.k8s.io` API, which is different from `custom.metrics.k8s.io` provided by
Prometheus Adapter. Both APIs serve the same use case but work differently.

You should now see `external.metrics.k8s.io` as _running_ in the output of `kubectl api-versions`.

## Autoscaling HPA based on CPU/Memory and Custom Metrics

You have to create a `ScaledObject`. DO NOT create a resource of kind `HorizontalPodAutoscaler` manually.
`ScaledObject` wraps it and will create it automatically.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: intensive-app
spec:
  scaleTargetRef:
    kind: Deployment
    name: intensive-app
  pollingInterval: 30
  cooldownPeriod: 300
  minReplicaCount: 1
  maxReplicaCount: 4
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 10
        scaleUp:
          policies:
            - type: Percent
              value: 100
              periodSeconds: 15
          selectPolicy: Max
          stabilizationWindowSeconds: 0
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-k8s.monitoring.svc:9090
        query: sum(autoscaleexp_custom_metric{deployment="intensive-app"}) + sum(another_custom_metric{deployment="intensive-app"})
        threshold: "100"
    - type: cpu
      metricType: Utilization
      metadata:
        value: "50"
```

The result of your query is compared against the threshold. **It should return a single element response.**

## Algorithm Behavior

- If you have multiple triggers, for example one trigger for CPU, one for memory and another
  for a prometheus query and each returns a different desired replica count then the maximum of those will be chosen.
- You can configure Stabilization window and Scaling policies to change how much time to wait before scaling and
  how fast should it scale.

## Docs

- [Pod Autoscaling Guide](../../docs/operations/monitoring/pod-autoscaling.md) — the Prometheus Adapter alternative.
- https://keda.sh/docs/2.10/concepts/scaling-deployments/
- https://keda.sh/docs/2.10/scalers/prometheus/
- https://keda.sh/docs/2.10/scalers/cpu/
- https://keda.sh/docs/2.10/scalers/memory/
