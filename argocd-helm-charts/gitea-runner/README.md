# Gitea Runner

> Superseded by [`gitea-actions`](../gitea-actions/README.md), which uses Gitea's official chart. New clusters
> should use that; this chart stays until existing clusters have migrated.

Runs [Gitea's `act_runner`](https://gitea.com/gitea/act_runner) (the Gitea Actions CI runner, `dind` image so
jobs can build/run containers) as a pod, registered against a Gitea instance with a runner token. Gitea
Actions jobs then execute inside this runner instead of on external CI infra.

* There are some custom changes, have asked the author if he will accept the [patch](https://gitea.com/vquie/act_runner-helm/issues/2)

* The fix is [here](https://gitlab.enableit.dk/kubernetes/k8id/-/merge_requests/940)

* Create the runner token

```sh
kubectl create secret generic gitea-runner-token --namespace gitea --dry-run=client --from-literal=act-runner-token='lolmyrunnertoken' -o yaml | kubeseal --controller-namespace system --controller-name sealed-secrets -o yaml
```

## Increase parallel jobs execution

```yaml
act-runner:
  act_runner:
    parallel_jobs: 5
```

* Doc is [here](https://gitea.com/gitea/act_runner)

## Private registry auth for job images

Provide a registry secret (sealed or normal) that contains `.dockerconfigjson` so the runner can pull images referenced in `act_runner.labels`.

Example sealed secret creation:

```sh
kubectl create secret docker-registry gitea-runner-registry \
  --namespace gitea \
  --docker-server=registry.example.com \
  --docker-username=example-user \
  --docker-password=example-token \
  --dry-run=client -o yaml | \
  kubeseal --controller-namespace system --controller-name sealed-secrets -o yaml
```

Values example:

```yaml
act-runner:
  act_runner:
    registrySecretName: gitea-runner-registry
    registrySecretMountPath: /runner/.docker
```

## Nodes without legacy iptables (nf_tables only)

The `dind` image points `iptables` at `iptables-legacy`. On nodes whose kernel has no legacy `ip_tables`
modules (e.g. Ubuntu 26.04, kernel 7.x) dockerd fails to start with
``can't initialize iptables table `nat': Table does not exist``, and the runner never registers.

Switch the pod to `iptables-nft` before the runner starts. Only `args` is overridden, so the image's
`tini` entrypoint stays PID 1:

```yaml
act-runner:
  args:
    - /bin/bash
    - -c
    - |
      sudo update-alternatives --set iptables /usr/sbin/iptables-nft
      sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
      exec /bin/bash /opt/run.sh
```

`command`, `args` and `strategy` are local additions to the vendored `act-runner` chart (upstream
`vquie/act-runner` 1.0.0 is unmaintained); re-vendoring it drops them. The defaults here use a `Recreate`
strategy, since the runner PVC is ReadWriteOnce, and `fsGroupChangePolicy: OnRootMismatch`.

## Create kube config secret

```bash
#!/bin/bash

set -euo pipefail

CLUSTERNAME=$1
SERVICEACCOUNT=$2
NAMESPACE=$3
CONFIG="/tmp/$CLUSTERNAME.config"

kubectl get secret $(kubectl get serviceaccount $SERVICEACCOUNT -n $NAMESPACE -o json | jq -r '.secrets[0].name' ) -n $NAMESPACE -o  json | jq -r '.data["ca.crt"]' | base64 --decode > /tmp/k8s-$CLUSTERNAME.ca.crt

kubectl config --kubeconfig $CONFIG set-cluster $CLUSTERNAME --embed-certs=true --server="https://kubernetes.default.svc" --certificate-authority=/tmp/k8s-$CLUSTERNAME.ca.crt

kubectl config --kubeconfig $CONFIG set-credentials $SERVICEACCOUNT --token=$(kubectl get secret $(kubectl get serviceaccount $SERVICEACCOUNT -n $NAMESPACE -o json | jq -r '.secrets[0].name') -n $NAMESPACE -o json | jq -r '.data.token'  | base64 --decode)

kubectl config --kubeconfig $CONFIG set-context $CLUSTERNAME --cluster=$CLUSTERNAME --user=$SERVICEACCOUNT

kubectl config --kubeconfig $CONFIG use-context $CLUSTERNAME

cat $CONFIG | base64 --wrap=0

```
