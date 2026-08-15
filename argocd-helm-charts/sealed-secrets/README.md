# Sealed Secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) lets you encrypt a Kubernetes `Secret` into a
`SealedSecret` that is safe to commit to a public or shared git repository. The `SealedSecret` can only be decrypted
by the controller running in the target cluster, using a private key that never leaves that cluster.

Concept: encryption uses a `public/private` key pair. Anyone can encrypt data with the controller's public key, but
only the controller (holding the private key) can decrypt it. So committing a `SealedSecret` to git is safe even
though the repo (and its history) is world-readable.

## Why it's in KubeAid

KubeAid is GitOps-driven: ArgoCD applies everything from git, including secrets referenced by other charts (repo
credentials, TLS certs, DB passwords). Sealed Secrets is what makes it safe to commit those secrets to the
`kubeaid-config` repo instead of managing them out-of-band.

## Key values

- `sealed-secrets.namespace` (values.yaml default: `system`) — namespace the controller Deployment runs in.
- `backup.enabled` / `backup.schedule` / `backup.provider` — the CronJob-based key backup described below.

### A note on the controller namespace

This chart's own `values.yaml` defaults `sealed-secrets.namespace` to `system`, which is what all the `kubeseal`
and `kubectl` commands in this README use. Current `kubeaid-cli`-provisioned clusters override this and install the
controller into a namespace literally named `sealed-secrets` (see `values-sealed-secrets.yaml.tmpl` in kubeaid-cli).
Neither is `kube-system` — before running any command below, confirm the real namespace with:

```sh
kubectl get pods -A -l app.kubernetes.io/name=sealed-secrets
```

and substitute it for `system` in the commands below if your cluster uses the `sealed-secrets` namespace instead.

## How to add a sealed secret

### Create a json/yaml-encoded secret somehow

You can turn any kubernetes secret into a sealed secret, so it doesnt matter how the normal secret was created, but here
are some examples of how to create a secret.

**note: use of `--dry-run` - this is just a local file!**

```sh
# create a generic secret foo=bar by using the STDIN
echo -n bar | kubectl create secret generic mysecret -n target-namespace-in-k8s --dry-run=client --from-file=foo=/dev/stdin -o json >mysecret.json

# create a generic secret username=mydevuser passed as the literal value
kubectl create secret generic mysecret -n target-namespace-in-k8s --dry-run=client --from-literal=username=mydevuser -o json >mysecret.json

# create a tls secret with specified tls.key and tls.crt files
kubectl create secret tls mysecret -n target-namespace-in-k8s --dry-run=client --key="tls.key" --cert="tls.crt" -o json >mysecret.json

# create a generic secret from a files contents (gets encoded as base64 and can be made available as file inside pod).
kubectl create secret generic alertmanagerconfig -n target-namespace --from-file=./alertmanager.yml --dry-run=client -o json >mysecret.json

# Create a dockerlogin secret which can be used f.ex. as image pullsecret
kubectl create secret --namespace system --dry-run=client docker-registry myDockerSecret --docker-server=<registry-url> --docker-username=xxx --docker-password=xxx -o json > mysecret.json
```

Using kubeseal, the secret can then be converted to a sealed secret.

```sh
# for using local public cert
kubeseal --cert secret-certificate.pem <mysecret.json >mysealedsecret.json

#for pulling public cert from service in cluster
kubeseal --controller-namespace system --controller-name sealed-secrets < mysecret.json > mysealedsecret.json
```

**mysecret.json** is your target secret file, which will generated to sealedsecret one (can be yaml format too)

**sealedsecret.json** is a new generated sealedsecret file (name can be changed also)

This can then be imported manually using kubectl apply for confirming.

You can use this f.ex to create sealed secrets for adding repos to ArgoCD.

(If you are using a token, the scope has to include full repo privilges, and the UN can be any **non-empty** string):

  ```sh
  kubectl create secret generic sample-git --namespace argocd --dry-run=client --from-literal=type='git' --from-literal=name='sample-git' --from-literal=url=https://gitlab.com/Obmondo/myreponame.git --from-literal=username='gitlab+deploy-token-20' --from-literal=password='lolpassword' --output yaml | yq eval '.metadata.labels.["argocd.argoproj.io/secret-type"]="repository"' - | yq eval '.metadata.annotations.["sealedsecrets.bitnami.com/managed"]="true"' - | yq eval '.metadata.annotations.["managed-by"]="argocd.argoproj.io"' - | kubeseal --controller-namespace system --controller-name sealed-secrets --format yaml - > argocdrepo-myreponame.yaml
  ```

### Important - verify

Look in `argocd -> applications -> secrets` and verify it shows your unsealed secret as well as the sealed one.. if the
unsealed one is not showing it is most likely because secret already exists in an unmanaged version, in which case you
must add an annotation to the existing secret:

```yaml
sealedsecrets.bitnami.com/managed: "true"
```

and then restart the sealed-secrets controller pod (in its namespace — see above) to make it do its job (it has
already given up at this point).

## Important Considerations

### `docker-registry` secret type is incompatible with `secretKeyRef`

Secrets of type `docker-registry` are **not** usable via `secretKeyRef` in pod environment variables or volume mounts.
They are exclusively designed to be consumed as `imagePullSecrets`. If you need to reference individual fields (e.g. a
registry password) from application config, create a separate secret instead.

### Namespace is bound at seal time and cannot be changed

When a SealedSecret is created, the namespace is cryptographically bound into the encryption. This means you **cannot**
move or re-use a SealedSecret in a different namespace — the controller will fail to decrypt it.
If you need the secret in a different namespace, you must go back to the original plaintext secret and re-seal it
with the correct target namespace from the start.

## Templating Sealed Secrets

Sealed secrets have an interesting feature which can use config files where only a
part of the file needs to be encrypted. To use templates in sealed secrets, create a
sealed secret yaml using the examples provided above, with palceholder values for data to
be sealed, and add the template part as given in the example below:

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  creationTimestamp: null
  name: example
spec:
  encryptedData:
    password: AgC2==
    access-token: AgDE==
  template:
    data:
      kubeaid-pushupdate.yaml: |
        repo-url: https://gitlab.com/example/repo.git
        username: smart_user
        password: "{{ index . "password" }}"
        repo-token: "{{ index . "access-token" }}"
    metadata:
      creationTimestamp: null
      namespace: test
```

The `encryptedData` field can store some random data for the start. All the referenced
fields in the `data` section, need to be present in the `encryptedData` before you attempt to seal the secret.
Then seal and merge the secret using the below command:

```sh
kubectl create secret generic example\
 --dry-run=client \
 --namespace test \
 --from-literal=password="super_secret_pass" \
 --from-literal=access-token="0123abcDEF" -o yaml | \
 kubeseal \
 --controller-namespace system \
 --controller-name sealed-secrets \
 --namespace test -o yaml \
 --merge-into sealedSecret.yaml
```

The `--merge-into` option only changes the encrypted data without changing the whole SealedSecret.
[Original Example](https://github.com/bitnami-labs/sealed-secrets/tree/main/docs/examples/config-template)

## How to backup and restore sealed secrets

### Manual way

We are basically backing up all the tls.crt & tls.key files of the cluster locally, so we can restore them later.

```sh
# This would get all the tls secrets in the cluster from all the name spaces.
kubectl get secrets -n system -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o yaml > backup_key.yml
```

This would backup the ``tls.crt`` & ``tls.key`` in a yaml file locally.

For restoring the secrets, in a cluster use .

```sh
# This would restore the tls secrets in the cluster from the backup file.
kubectl apply -f backup_key.yml
```

### Automated way

#### Velero

Run the commands from the velero pod in the cluster .

We are backing up the system namespace which contains the sealed secrets if there is no shedule backup already present.
If there is sheduled backup already present skip this command.

```sh
# This would create backup of the sealesecret pod in system namespace.
velero backup create <backup-name> --include-namespaces system --include-resources pods --selector sealedsecrets.bitnami.com/sealed-secrets-key=active
```

Assuming we already have scheduled backup .
Check the backup status using the following command.

```sh
velero get backups
```

Restore the backup with the name that is created/exists.

```sh
velero restore create <restore-name> --include-namespaces system --include-resources pods --selector sealedsecrets.bitnami.com/sealed-secrets-key=active --from-backup <backup-name>
```

#### CronJob

Backup sealed secrets via [cronjob](./templates/cronjob.yaml). Controlled by `backup.enabled` / `backup.schedule` /
`backup.provider` in values.yaml.

### Backup Setup on aws

Create the s3 bucket

```sh
aws s3api create-bucket --bucket kbm-sealed-secrets-backups --region eu-west-1 --endpoint-url=https://s3.obmondo.com
```

## Docs

- [Backup & Restore overview](../../docs/operations/backup-restore.md) — how this fits into the broader DR strategy.
