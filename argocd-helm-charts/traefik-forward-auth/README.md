# Traefik Forward Auth

Wraps the [mesosphere/traefik-forward-auth](https://github.com/mesosphere/traefik-forward-auth) chart — an
OIDC forward-auth service. Traefik forwards incoming requests to it via a middleware, it authenticates the
user against an OIDC provider (Keycloak), and returns allow/deny (plus optional RBAC on top of the OIDC
claims) before Traefik lets the request through.

## Why it's in KubeAid

Puts OIDC login + RBAC in front of internal ingress-exposed apps (dashboards, admin UIs) that don't have
their own auth, without changing the app. It's deployed alongside the `traefik` chart, which is where the
`traefik-traefik-forward-auth@kubernetescrd` middleware and the `traefikForwardAuth` client config it depends
on live.

## Key values

`argocd-helm-charts/traefik-forward-auth/values.yaml`:

- `traefikForwardAuth.enabled: true`, `clientId: traefik-forward-auth` — the OIDC client used against Keycloak.
- `traefikForwardAuth.enableRBAC: false` — RBAC checks (see below) are off by default; flip to `true` per
  the [example values](./examples/values.yaml) to enforce ClusterRole/ClusterRoleBinding-based authorization.
- `middleware.enabled: true` — installs the Traefik middleware resource that ingress objects reference.

## RBAC Support

* Setup the value [file](./examples/values.yaml)
* Configure the traefik-forward-auth client on keycloak
* Add required annotation to your ingress object

  ```yaml
  ---
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    traefik.ingress.kubernetes.io/router.middlewares: traefik-traefik-forward-auth@kubernetescrd
  ```

* Create a clusterrole and clusterrolebinding

  ```yaml
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRole
  metadata:
    name: foo-whoami
  rules:
  - nonResourceURLs:
    - /dashboard
    - /admin
    # Regex pattern will work when `ENABLE_V3_URL_PATTERN_MATCHING:` is enabled in values file
    - ~^https?://whoami-auth\.kubeaid\.io/
    - ~^https?://traefik\.kubeaid\.io/
    - ~^https?://queue\.job\.kubeaid\.io/
    verbs:
    - get

  ---
  # Group
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: sre-whoami-binding
  subjects:
  - kind: Group
    name: oidc:sre
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: foo-whoami

  ---
  # User
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: foo-whoami-binding
  subjects:
  - kind: User
    name: foo@kubeaid.io
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: foo-whoami
  ```

* Open the link on your browser (whatever domain you have given in your ingress object).
  It should first authenticated you and if the requested endpoint is allowed for that user
  or group it will give 200 otherwise 404 (Not Authorized)

## Debug

* Look at the traefik-forward-auth pods logs to see why the user is getting 404
