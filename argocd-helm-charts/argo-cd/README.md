# Argo CD

[Argo CD](https://argo-cd.readthedocs.io/) is a declarative GitOps continuous-delivery controller for Kubernetes:
it watches Git repositories and keeps cluster state in sync with the manifests (here: Helm charts + values) they
declare.

## Why it's in KubeAid

Argo CD **is** the engine the whole platform runs on. Every directory under `argocd-helm-charts/` is a wrapper
chart that a per-cluster Argo CD Application (defined in your kubeaid-config repo and created by the root app)
deploys — the [Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md). This chart deploys Argo CD
itself the same way, so after bootstrap Argo CD manages its own upgrades from Git too.

Upstream chart: [`argo-cd`](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd) from argo-helm.

## Key values / KubeAid-specific configuration

Upstream values live under the `argo-cd:` key. KubeAid defaults (`values.yaml`):

- `configs.cm.application.resourceTrackingMethod: annotation` — required for the Crossplane integration: cluster-
  scoped XRs generated from an XR Claim inherit the `argocd.argoproj.io/instance` *label*, which would leave the
  tracking app permanently out-of-sync (and prune-dangerous). Annotation tracking avoids that.
- A long `configs.cm.resource.exclusions` list — Endpoints/EndpointSlices, Leases, authn/authz reviews, CSRs,
  Cilium identities/endpoints, Kyverno reports, Velero and CNPG `Backup`s — to cut watched events and UI clutter.
- `dex.enabled: false` (SSO is done via Keycloak OIDC instead, configured per cluster), `installCRDs: false`.
- Prometheus `metrics` + `ServiceMonitor` enabled on controller, server, repo-server, redis, and notifications,
  with modest resource requests/limits on all components. `blackbox.probe: true` adds a blackbox-exporter probe.

Two KubeAid-specific manifests ship in this wrapper's `templates/`:

- `kubeaidAppProject.enabled` (default `true`) — an `AppProject` named `kubeaid` that all KubeAid Applications
  belong to (allows all source repos, destinations, and resource kinds).
- A ConfigMap declaring the `kubeaid-agent` local account with `apiKey` capability, used to generate API tokens
  for automation.

Repository credentials are **not** in values: Argo CD needs one Secret per Git repo, created as a SealedSecret
(labelled `argocd.argoproj.io/secret-type: repository`) in the `sealed-secrets/argocd/` directory of your
kubeaid-config repo. The admin password lives in the `argocd-secret` Secret, also managed as a SealedSecret.

## Operational notes

- Bootstrap is the one manual step: after cluster creation, render and apply the root app from your
  kubeaid-config repo:

  ```sh
  helm template k8s/<clustername>/argocd-apps --show-only templates/root.yaml | kubectl apply -f -
  ```

  Argo CD takes over from there.
- Never `helm install/upgrade` charts directly on a KubeAid cluster — Argo CD renders and applies everything, so
  the only lever is the values files in Git.
- Avoid force/replace syncs of the argo-cd app itself; that can take Argo CD down mid-sync. In the UI,
  "out-of-sync" doesn't necessarily mean "missing" — check the compact app diff before assuming so.

### Argo CD CLI

- Install: `curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd`
- Log in via the Kubernetes API server (after pointing kubeconfig at the target cluster):

  ```sh
  kubectl config set-context --current --namespace=argocd
  argocd login <argocd-server-url> --core
  ```

- From a shell inside the argocd-server pod you can instead log in against the pod itself:
  `argocd login <podname>:8080` (default port `8080`).

### Create an Argo CD API token

Assumes a user with `apiKey` capability already exists (the `kubeaid-agent` local account this chart's ConfigMap
declares is one such user):

```sh
# login using admin creds
argocd login <argocd ingress> --username admin --password <admin password>

# List all argocd accounts to make sure the user with apikey capabilities are there
argocd account list

# Create a password for that user
argocd account update-password --account apiuser --current-password <existing admin user password> --new-password <newpassword>

# Generate the token using user
argocd account generate-token -a apiuser --server-name <argocd ingress>
```

### Create / reset the admin password

Create (as a fresh SealedSecret):

```sh
gopass pwgen 30
bcrypt-tool hash <generated-password> 10   # sudo snap install bcrypt-tool

kubectl create secret generic argocd-secret --namespace argocd --dry-run=client \
  --from-literal=admin.password='<bcrypt-hash>' \
  --from-literal=admin.passwordMtime="$(date +%FT%T%Z)" \
  --from-literal=server.secretkey='<random-string>' \
  --output=yaml | kubeseal --controller-name sealed-secrets-controller --controller-namespace sealed-secrets -o yaml > argocd-secret.yaml

kubectl apply -f argocd-secret.yaml   # apply directly - argocd is down, you can't sync
```

Then delete the `argo-cd-argocd-server-*` pod(s) so the Deployment recreates them, and once Argo CD is back sync
the sealed-secret app so it matches Git.

Reset in place on a running cluster (leading space before `bcrypt-tool` is intentional — keeps the plaintext
password out of shell history):

```sh
 bcrypt-tool hash "newpassword" 10

kubectl -n argocd patch secret argocd-secret -p '{"stringData": { "admin.password": "<bcrypt-hash>", "admin.passwordMtime": "'$(date +%FT%T%Z)'" }}'
```

then kill the `argo-cd-argocd-server-*` pod(s).

### Adding a Git repo

Argo CD needs one Secret per repo (see the SealedSecret note above). With `yq` and `kubeseal` installed:

```sh
kubectl create secret generic repo-token-name --namespace argocd --dry-run=client \
  --from-literal=type='git' --from-literal=name='repo-token-name' \
  --from-literal=url='https://gitea.obmondo.com/EnableIT/repo-name.git' \
  --from-literal=username='enableit_bot' --from-literal=password='SECRETPASSWORD' \
  --output yaml \
| yq eval '.metadata.labels.["argocd.argoproj.io/secret-type"]="repository"' - \
| yq eval '.metadata.annotations.["sealedsecrets.bitnami.com/managed"]="true"' - \
| yq eval '.metadata.annotations.["managed-by"]="argocd.argoproj.io"' - \
| kubeseal --controller-namespace sealed-secrets --controller-name sealed-secrets-controller --format yaml - > repo-token-name.yaml

kubectl apply -f repo-token-name.yaml -n argocd
```

Confirm in the UI under Settings -> Repositories — `CONNECTION STATUS` should read `Successful`. To switch an
existing app to a different source repo, edit its manifest (or, for single-source apps, the Summary tab) from
the app's page in the UI, then re-sync.

### Keycloak OIDC

Upstream doc: <https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/keycloak/#keycloak-and-argocd-with-pkce>
(follow it for the Keycloak client/groups setup — pick the realm your users are in, not the master realm). Add
to this chart's `configs` values:

```yaml
rbac:
  policy.csv: |
    g, ArgoCDAdmins, role:admin
    g, ArgoCDDevs, role:readonly
  scopes: '[groups, email]'
cm:
  oidc.config: |
    name: Keycloak
    issuer: https://keycloak.obmondo.com/auth/realms/Obmondo
    clientID: argocd
    clientSecret: $oidc.keycloak.clientSecret
    requestedScopes: ["openid", "profile", "email", "groups"]
```

and set `oidc.keycloak.clientSecret` on the `argocd-secret` SealedSecret (merge into an existing one with
`kubeseal --merge-into`). Grant admin access by adding a Keycloak user to the matching group under Users ->
select user -> Groups.

Troubleshooting: confirm `argocd-secret` in the `argocd` namespace has an `oidc.keycloak.clientSecret` key,
check the user's group memberships in the Keycloak UI, and match `policy.csv` against those group names.

### Troubleshooting

- **Application stuck in `Progressing`**: a known interaction between Argo CD and Traefik (and a few other
  ingress controllers) — see <https://github.com/traefik/traefik/issues/3377>. `status.loadBalancer` on the
  argocd-server Ingress stays empty. Check with
  `kubectl -n argocd get ing argo-cd-argocd-server -o jsonpath={.status}`.
- **`spec.source.repoURL and spec.source.path either spec.source.chart are required`** after an upgrade: the
  Application CRD didn't pick up its new schema. Re-apply it (`kubectl apply -f application-crd.yaml`, or add
  `--server-side` if that fails). Do not delete the CRD hoping Argo CD regenerates it — that takes down every
  Application using it.
- **`ComparisonError: groupVersion shouldn't be empty`**: an Application manifest (usually the root one) has the
  wrong `apiVersion`.

## Docs links

- Upstream: <https://argo-cd.readthedocs.io/> and the
  [argo-helm chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [Application CRD spec](https://github.com/argoproj/argo-cd/blob/master/manifests/crds/application-crd.yaml)
- [Helm value files from an external Git repo (multi-source Applications)](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/#helm-value-files-from-external-git-repository)
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
- [KubeAid: GitOps drift detection](../../docs/kubeaid/gitops-drift-detection.md)
