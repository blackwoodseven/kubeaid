# Matomo

[Matomo](https://matomo.org) is an open-source, self-hosted web analytics platform — a privacy-respecting
alternative to Google Analytics where visitor data stays on your own infrastructure.

This is a KubeAid wrapper around the [Bitnami matomo chart](https://github.com/bitnami/charts/tree/main/bitnami/matomo)
(version 11.0.0), with the bundled MariaDB replaced by a database managed through the
[mariadb-operator](../mariadb-operator).

## Why it's in KubeAid

Self-hosted analytics with the database run the KubeAid way: instead of Bitnami's in-chart MariaDB
(`matomo.mariadb.enabled: false`), this chart renders `k8s.mariadb.com/v1alpha1` custom resources — a `MariaDB`
instance (`matomo-mariadb`), a `Database`, a `Grant` for the `matomo` user, and an optional logical-backup
CronJob (`ghcr.io/obmondo/mariadb-logical-backup`).

## Prerequisites

- `mariadb-operator` installed on the cluster (reconciles the `MariaDB`/`Database`/`Grant` CRs).
- Storage: `mariadb.storage.storageClassName` defaults to `zfs-localpv`. With rook-ceph the MariaDB liveness and
  readiness probes were failing because the root password did not get set properly — hence the default.

## Key values / KubeAid-specific configuration

| Value | Default | Meaning |
|---|---|---|
| `matomo.image.*` | `bitnamilegacy/matomo:5.1.1` | Pinned app image (Bitnami legacy registry). |
| `matomo.externalDatabase.*` | host `matomo-mariadb` | Points Matomo at the operator-managed database. |
| `matomo.externalDatabase.existingSecret` | `matomo-user` | Secret with the DB password under the `db-password` key. |
| `mariadb.rootPasswordSecretKeyRef` | `matomo-secrets` / `MARIADB_ROOT_PASSWORD`, `generate: true` | Operator generates the root password. Cannot be removed with zfs-localpv (PVC stays Pending otherwise). |
| `mariadb.passwordSecretKeyRef` | `matomo-user` / `db-password`, `generate: true` | Key name must stay `db-password` — it is what `externalDatabase.existingSecret` looks up. |
| `mariadb.storage.size` | `1Gi` | In-use volume resize + wait are enabled. |
| `mariadb.logicalbackup.enabled` | `true` | Daily dump CronJob (default schedule `30 00 * * *`). |

## Single sign-on via Keycloak (OIDC)

Matomo has no built-in OIDC; the [LoginOIDC plugin](https://plugins.matomo.org/LoginOIDC) provides it.

1. In Keycloak, create a client in your realm: Client ID `matomo`, access type *confidential*, standard flow
   enabled, valid redirect URIs `https://<matomo>/index.php?module=LoginOIDC&action=callback&provider=oidc` and
   `https://<matomo>`, web origins `+`. Note the client secret from the Credentials tab.
2. In Matomo (as superuser), install and activate **LoginOIDC** from *Settings → Platform → Marketplace*.
3. Under *General Settings → LoginOIDC*, enable **Create new users when users try to log in with unknown OIDC
   accounts**, then fill in the endpoints (from the realm's *OpenID Endpoint Configuration*):
   - Authorize / Token / Userinfo URL: `https://<keycloak>/auth/realms/<realm>/protocol/openid-connect/{auth,token,userinfo}`
   - Logout URL: `.../openid-connect/logout?redirect_uri=https://<matomo>`
   - Userinfo ID: `preferred_username`; Client ID `matomo` + the client secret; OAuth scopes `openid email profile`.
4. A "Keycloak" button appears on the login screen. First-time OIDC users have no site permissions — assign them
   under *System → Users*.

## Operational notes

Matomo allows only [one superuser](https://matomo.org/faq/general/faq_69/) through the UI by default. To grant
superuser to more users, set it directly in the database (exec into the MariaDB pod):

```sql
mariadb -u root -p$MARIADB_ROOT_PASSWORD    -- no space after -p
use <db_name>;
UPDATE `matomo_user` SET superuser_access = 1 WHERE `login` = 'username-here';
```

## Docs links

- Matomo: <https://matomo.org> — LoginOIDC plugin: <https://plugins.matomo.org/LoginOIDC>
- Upstream chart: <https://github.com/bitnami/charts/tree/main/bitnami/matomo>
- mariadb-operator: <https://github.com/mariadb-operator/mariadb-operator>
