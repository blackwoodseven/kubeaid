# Teleport Kube Agent

This chart deploys the [Teleport](https://goteleport.com) kube-agent — a lightweight agent that joins a managed
cluster's Kubernetes API to the central [`teleport-cluster`](../teleport-cluster/README.md) (see `proxyAddr` in
values.yaml), so operators access it through Teleport instead of a distributed kubeconfig.

> **Deprecated:** Teleport is no longer KubeAid's default access layer — new clusters use the NetBird mesh with
> Keycloak SSO instead. This chart remains available for existing setups.

## Why it's in KubeAid

This is the per-managed-cluster half of KubeAid's previous Teleport-based access model: `teleport-cluster` runs the
central proxy/auth service, and every managed cluster runs this agent to expose its API through it. On current
clusters that role is filled by NetBird (mesh access) and Keycloak (SSO).

**NOTE: if there is no join-token secret, the pod would fail to start.**

## Setup

### Get the cert from sealed-secrets (optional — for info only)

```sh
kubectl get secret --namespace system -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o jsonpath='{'.items[0].data."tls\.crt"'}' | base64 -d > /tmp/staging.pem
```

### Generate the join-token secret

`joinTokenSecret.name` in values.yaml (default `teleport-kube-agent-join-token`) must match the secret created here:

```sh
kubectl create secret generic teleport-kube-agent-join-token -n obmondo --dry-run=client --from-literal=auth-token=xxx -o yaml | kubeseal --controller-name sealed-secrets --controller-namespace system --cert /tmp/staging.pem -o yaml - > /tmp/teleport-kube-agent-join-token.yaml
```

> NOTE: `--controller-namespace system` above is this chart's default sealed-secrets controller namespace — see the
> [sealed-secrets README](../sealed-secrets/README.md#a-note-on-the-controller-namespace) if your cluster deploys
> the controller elsewhere.

## Docs

- [teleport-cluster](../teleport-cluster/README.md) — the central Teleport cluster this agent joins.
