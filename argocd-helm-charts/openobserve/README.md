# OpenObserve Installation Guide

> **Tip:** Before installing OpenObserve, you must deploy the **OpenTelemetry Collector**.  
> Add it as a regular Argo CD application in your `kubeaid-config` repository.

---

## Create Sealed Secrets for PostgreSQL

```sh
kubectl create secret generic openobserve-pg-credentials \
  --namespace openobserve \
  --from-literal=LOGICAL_BACKUP_AZURE_STORAGE_ACCOUNT_KEY="<azure-storage-account-key>" \
  --from-literal=username="openobserve" \
  --from-literal=password="Batman123" \
  --dry-run=client -o yaml | kubeseal --controller-namespace system \
  --controller-name sealed-secrets-controller \
  -o yaml > k8s/my-cluster/sealed-secrets/openobserve/openobserve-pg-credentials.yaml
```

The resulting file `openobserve-pg-credentials.yaml` is now a sealed secret ready for Argo CD.

## Configure values.yaml for External Secrets, Dex, and RBAC

To avoid hardcoding secrets in your Git repository and to ensure Keycloak groups map correctly to OpenObserve's OpenFGA backend, configure your `values.yaml` as follows:

Critical: Ensure `insecureEnableGroups: true` is set, or Dex will silently drop the Keycloak roles.

```yaml
openobserve:
  externalSecret:
    enabled: true
    name: openobserve-credentials

  enterprise:
    enabled: true
    openfga:
      enabled: true
    dex:
      enabled: true
      config:
        issuer: https://dex.your-cluster-ingress.com/dex
        staticClients:
          - id: internalclient
            redirectURIs:
              - https://openobserve.your-cluster-ingress.com/config/redirect
            name: internalclient
            secretEnv: O2_DEX_CLIENT_SECRET
        oauth2:
          responseTypes:
            - code
          skipApprovalScreen: true
        connectors:
          - type: oidc
            id: openobserve
            name: openobserve
            config:
              issuer: https://keycloak.your-cluster-ingress.com/auth/realms/Kilroy
              clientID: openobserve
              clientSecret: $KEYCLOAK_CLIENT_SECRET
              redirectURI: https://dex.your-cluster-ingress.com/dex/callback
              
              # CRITICAL: Required for Dex to process upstream Keycloak groups
              insecureEnableGroups: true
              
              # Ensure "roles" is explicitly requested
              scopes: ["profile", "email", "groups", "roles", "offline_access"]
              getUserInfo: true
              claimMapping:
                email: email
                name: name
                groups: role # Maps the Keycloak "role" claim to the Dex "groups" claim
      parameters:
        O2_CALLBACK_URL: https://openobserve.your-cluster-ingress.com/web/cb
        O2_DEX_SCOPES: openid profile email groups offline_access
        O2_DEX_DEFAULT_ORG: default
        O2_DEX_DEFAULT_ROLE: viewer
        O2_DEX_ROLE_ATTRIBUTE: "groups" # OpenObserve reads the groups array from Dex
        O2_DEX_NATIVE_LOGIN_ENABLED: "true"
```

## Keycloak & OpenObserve Group Mapping

To pass custom team groups (e.g., `OpenObserveAdmin`, `SRE`, `ArgoCDAdmins`) from Keycloak to OpenObserve, you must flatten the claim in Keycloak and map the permissions in OpenObserve.

### 1. Keycloak Mapper Configuration

In Keycloak, navigate to the **openobserve** Client -> **Client Scopes** -> your dedicated scope -> **Add Mapper (User Client Role)**. Configure it exactly as follows so Dex can read the array:

* **Token Claim Name:** `role`
* **Multivalued:** `ON`
* **Claim JSON Type:** `String`
* **Add to ID token / access token / userinfo:** `ON`

### 2. Map Permissions in OpenObserve

When a user logs in, OpenObserve will automatically create a User Group matching the Keycloak group name (e.g., `OpenObserveAdmin`). Because it is a custom group, it has zero permissions by default.

1. Log into OpenObserve using the root local account (`root@example.com`).
2. Navigate to **IAM** > **User Groups**.
3. Select the automatically created group (e.g., `OpenObserveAdmin`).
4. Under the **Roles** tab, toggle the view to **All** and check the built-in role you want to apply (e.g., check `admin` to grant the group full root privileges, or `viewer` for read-only).

## Populate the Credentials Sealed Secret

Run the command below to inject the real values and seal the secret.

```sh
kubectl create secret generic openobserve-credentials \
  --namespace openobserve \
  --from-literal=ZO_ROOT_USER_EMAIL="root@example.com" \
  --from-literal=ZO_ROOT_USER_PASSWORD="Complexpass#123" \
  --from-literal=AZURE_STORAGE_ACCOUNT_KEY="<azure-storage-account-key>" \
  --from-literal=AZURE_STORAGE_ACCOUNT_NAME="<azure-storage-account-name>" \
  --from-literal=ZO_META_POSTGRES_DSN="postgres://openobserve:Batman123@openobserve-postgres-rw.openobserve:5432/app" \
  --from-literal=OPENFGA_DATASTORE_URI="postgres://openobserve:Batman123@openobserve-postgres-rw.openobserve:5432/app" \
  --from-literal=ZO_TRACING_HEADER_KEY="Authorization" \
  --from-literal=ZO_TRACING_HEADER_VALUE="Basic <opentelemtry-token-from-openobserve-data-sources>" \
  --from-literal=ZO_SMTP_USER_NAME="ABAAQQQQFFFFF" \
  --from-literal=ZO_SMTP_PASSWORD="+fjlahsguykevfkajvjk#jsbj43" \
  --from-literal=O2_DEX_CLIENT_SECRET="<dex-client-secret-for-internal-client>" \
  --from-literal=KEYCLOAK_CLIENT_SECRET="<keycloak-oidc-client-secret>" \
  --from-literal=OPENOBSERVE_AUTH_TOKEN="Basic <opentelemtry-token-from-openobserve-data-sources>" \
  --from-literal=OPENOBSERVE__K8S_EVENTS_AUTH_TOKEN="Basic <opentelemtry-token-from-openobserve-data-sources>" \
  --dry-run=client -o yaml | kubeseal --controller-namespace system \
  --controller-name sealed-secrets-controller \
  -o yaml --merge-into k8s/my-cluster/sealed-secrets/openobserve/openobserve-credentials.yaml
```

### Quick reference of the keys you just set

| Key | Example value/info |
| :--- | :--- |
| `ZO_ROOT_USER_EMAIL` | `root@example.com` |
| `ZO_ROOT_USER_PASSWORD` | `Complexpass#123` |
| `AZURE_STORAGE_ACCOUNT_KEY` | `<azure-storage-key>` |
| `AZURE_STORAGE_ACCOUNT_NAME` | `openobservestorage` |
| `ZO_META_POSTGRES_DSN` | `postgres://openobserve:Batman123@openobserve-postgres-rw.openobserve:5432/app` |
| `OPENFGA_DATASTORE_URI` | same as above |
| `ZO_TRACING_HEADER_KEY` | `Authorization` |
| `ZO_TRACING_HEADER_VALUE` | `Basic <opentelemtry-token-from-openobserve-data-sources>` |
| `ZO_SMTP_USER_NAME` | `ABAAQQQQFFFFF` |
| `ZO_SMTP_PASSWORD` | `+fjlahsguykevfkajvjk#jsbj43` |
| `O2_DEX_CLIENT_SECRET` | `<dex-client-secret-for-internalclient>` |
| `KEYCLOAK_CLIENT_SECRET` | `<keycloak-oidc-client-secret>` |
| `OPENOBSERVE_AUTH_TOKEN` | `Basic <opentelemtry-token-from-openobserve-data-sources>` |
| `OPENOBSERVE__K8S_EVENTS_AUTH_TOKEN` | same as above |

*All commands assume you have `kubectl`, `kubeseal` installed.
Ensure you've access to the `system` namespace where the sealed-secrets controller runs.*

## Troubleshooting

### Flushed OpenFGA User Cache (Role Updates)

OpenObserve's OpenFGA engine permanently maps a user to a role the first time they log in. If a user logs in before their Keycloak roles are correctly configured, they may be stuck with the fallback `Viewer` or `Editor` role, even after Keycloak is fixed.

To force OpenObserve to read the token fresh and re-provision the user with their proper groups, you must delete their cached account via API and have them log back in. The UI does not provide a deletion option.

```sh
curl -X 'DELETE' \
  'https://openobserve.your-cluster-ingress.com/api/default/users/<user-email-to-remove>' \
  -u '<root-user-email>:<root-user-password>' \
  -H 'accept: application/json'
```

## Extras
- [A short explanation on how Open Observe manages memory](https://github.com/openobserve/openobserve/discussions/2711)
