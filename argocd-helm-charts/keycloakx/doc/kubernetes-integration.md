# Kubernetes Client & Cluster Integration

This document covers installing `krew` and `oidc-login`, configuring the Kubernetes client in Keycloak, setting up local `kubeconfig` authentication, and configuring Keycloak group-based Kubernetes RBAC.

---

## Table of Contents
- [Prerequisites: Krew & oidc-login](#prerequisites-krew--oidc-login)
- [Setup the Kubernetes Client in Keycloak](#setup-the-kubernetes-client-in-keycloak)
- [Setup the Client Side (kubectl oidc-login & kubeconfig)](#setup-the-client-side-kubectl-oidc-login--kubeconfig)
- [Create Keycloak Group based Cluster RBAC authorization](#create-keycloak-group-based-cluster-rbac-authorization)

---

## Prerequisites: Krew & oidc-login

### Install krew plugin manager

Reference docs:
- <https://krew.sigs.k8s.io/docs/user-guide/setup/install/>
- <https://krew.sigs.k8s.io/docs/user-guide/quickstart>

```sh
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"${OS}_${ARCH}" &&
  "$KREW" install krew
)
```

Amend your shell configuration file (e.g. `~/.bashrc` or `~/.zshrc`):

```sh
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

### Install the oidc-login client

```sh
kubectl krew install oidc-login
```

Details about setup:
- <https://github.com/int128/kubelogin/blob/master/docs/setup.md>

---

## Setup the Kubernetes Client in Keycloak

* Log into the keycloak server using your personal admin user
* Go to the `<customer_name>` realm
* Go to clients and click on `Create`.
* Provide the `Client ID` as `kubernetes`, leave `Client Protocol` as `openid-connect`, `Root URL` as blank, and click on save.
* In the "Kubernetes" client details find "Valid redirect URLs" and add `http://localhost` and click "Save".
* Enable Role/Group membership to be included in the tokens:
  * Mappers -> Add Builtin
  * Enable `groups` checkbox
  * Click `Add selected`

---

## Setup the Client Side (kubectl oidc-login & kubeconfig)

* Run the setup command:

    ```sh
    export KEYCLOAK_URL="https://keycloak.your.domain.com/auth/realms/master"
    export CLIENT_ID=kubernetes
    export CLIENT_SECRET=kubernetes

    kubectl oidc-login setup --oidc-issuer-url=$KEYCLOAK_URL --oidc-client-id=$CLIENT_ID --oidc-client-secret=$CLIENT_SECRET
    ```

* Bind a cluster role:
  1. After running the setup command above, use the output to configure your clusterrolebinding (adjust `<your-username>` accordingly).
  2. The URL must match the output of the setup command.

        ```sh
        kubectl create clusterrolebinding <your-username>-oidc-cluster-admin --clusterrole=cluster-admin --user='$KEYCLOAK_URL#<your-keycloak-userID>'
        ```

* Set up the Kubernetes API server (add to `kube-apiserver` configuration):

    ```raw
    --oidc-issuer-url=$KEYCLOAK_URL
    --oidc-client-id=$CLIENT_ID
    ```

    > *Note*: Kubernetes admin should have already configured this via puppet/kops.

* Set up `kubeconfig`:

  1. Add the OIDC user using `kubectl`:

      ```bash
      kubectl config set-credentials oidc \
        --exec-api-version=client.authentication.k8s.io/v1beta1 \
        --exec-command=kubectl \
        --exec-arg=oidc-login \
        --exec-arg=get-token \
        --exec-arg=--oidc-issuer-url=$KEYCLOAK_URL \
        --exec-arg=--oidc-client-id=$CLIENT_ID \
        --exec-arg=--oidc-client-secret=$CLIENT_SECRET
      ```

  2. Alternatively, directly add the configuration snippet into your `kubeconfig`:

      ```yaml
      users:
      - name: oidc
        user:
          exec:
            apiVersion: client.authentication.k8s.io/v1beta1
            args:
            - oidc-login
            - get-token
            - --oidc-issuer-url=$KEYCLOAK_URL
            - --oidc-client-id=$CLIENT_ID
            - --oidc-client-secret=$CLIENT_SECRET
            command: kubectl
            env: null
            provideClusterInfo: false
      ```

  3. Set the `oidc` user for the current context:

      ```bash
      kubectl config set-context --user oidc $(kubectl config get-contexts -o name)
      ```

* Verify cluster access:

  ```bash
  kubectl get nodes
  ```

---

## Create Keycloak Group based Cluster RBAC authorization

* Log into Keycloak as admin
* Go to your client (`kubernetes` in this case)
* In your client, navigate to `Mappers` & click `Create`
* Create a new mapper as shown below:

  ![new mapper](../static/mapper.png)

* Create the groups in Keycloak:
  1. From [Keycloak homepage](https://keycloak.your.domain.com/auth/admin/master/console/), go to [groups](https://keycloak.your.domain.com/auth/admin/master/console/#/realms/master/groups) and click `New`
  2. Provide the group's name and click save.

* Add users to the group:
  1. Go to [users](https://keycloak.your.domain.com/auth/admin/master/console/#/realms/master/users) and click `View all users`
  2. Select the user and navigate to `Groups`
  3. Select the target group from the `Available Groups` table and click `Join`

* Create the RBAC policy in the Kubernetes cluster:

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: sre-admin
    subjects:
    - kind: Group
      name: <Keycloak groups name>
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: ClusterRole
      name: <clusterRole name that you want to map the group to>
      apiGroup: rbac.authorization.k8s.io
    ```

* Refresh your `id-token` retrieved from Keycloak.
