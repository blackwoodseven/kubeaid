# Operations, Maintenance & Disaster Recovery

This document covers upgrading Keycloak, disaster recovery procedures (realm exports/imports), database migrations (Zalando to CNPG Postgres), troubleshooting, and helpful references.

---

## Table of Contents
- [Disaster Recovery](#disaster-recovery)
- [Migrating Keycloak from Zalando to CNPG](#migrating-keycloak-from-zalando-to-cnpg)
- [Troubleshooting](#troubleshooting)
- [Good Reads & References](#good-reads--references)

---

## Disaster Recovery

Keycloak recovery and reconfiguration can be done by exporting and importing realm settings:

### Manual Realm Export / Import via Web UI
* Log in to Keycloak as admin
* Go to `https://<keycloak-url>/auth/admin/master/console/#/realms/master/partial-export`
* Toggle `Export groups and roles` -> **ON**
* Toggle `clients` -> **ON**
* Click **Export**

This downloads the realm configuration as a `.json` file, which can later be imported via `https://<keycloak-url>/auth/admin/master/console/#/realms/master/partial-import`.

### Recovery via ArgoCD
Alternatively, deleting the Keycloak application in ArgoCD UI will retain the PVC/PV. When re-syncing the root app and Keycloak next, it attaches to the existing PVC/PV and restores state to the previous checkpoint.

---

## Migrating Keycloak from Zalando to CNPG

Keycloak stores operational state in a PostgreSQL database. Backing up and restoring the `keycloak` database transfers all state to CloudNativePG (CNPG).

> **⚠️ WARNING:** This migration requires scheduled service downtime. Ensure back-ups are created before proceeding.

### Migration Procedure:
1. Point the Keycloak Helm chart to a feature branch or tag enabling the CNPG cluster resource in ArgoCD. Disable Zalando PGSQL in `values.yaml`.
2. Sync the `kind: Cluster` resource from ArgoCD UI (creates a clean CNPG database instance).
3. Do **not** sync the Keycloak StatefulSet yet.
4. Shell into the existing Zalando PGSQL pod and dump the `keycloak` database:
    ```sh
    pg_dump -d keycloak -U keycloak -f keycloak_db.dump
    ```
5. Copy `keycloak_db.dump` from Zalando pod to local machine.
6. Copy `keycloak_db.dump` from local machine to destination CNPG pod.
7. Shell into the CNPG pod and restore the database dump:
    ```sh
    psql -d keycloak < keycloak_db.dump
    ```
8. Sync the Keycloak StatefulSet from ArgoCD UI and monitor database migrations.
9. Verify Keycloak becomes healthy on the new CNPG database cluster.

---

## Troubleshooting

### Resetting OIDC Cache & Cluster Role Bindings
If experiencing authentication state or token errors:

```bash
# Clear local OIDC token cache
rm -rf ~/.kube/cache/oidc-login

# Remove existing clusterrolebinding and recreate via setup steps
kubectl delete clusterrolebinding <your-username>-oidc-cluster-admin
```

---

## Good Reads & References

* [GitHub as Identity Provider in Keycloak](https://medium.com/keycloak/github-as-identity-provider-in-keyclaok-dca95a9d80ca)
* [Keycloak Identity Brokering Video Tutorial](https://www.youtube.com/watch?v=duawSV69LDI)
* [Keycloak as Identity Broker and Identity Provider](https://medium.com/keycloak/keycloak-as-an-identity-broker-an-identity-provider-af1b150ea94)
* [PostgreSQL Backup & Restore Documentation](https://www.postgresql.org/docs/current/backup-dump.html#BACKUP-DUMP-RESTORE)
* [Keycloak-to-Keycloak Identity Brokering Walkthrough](keycloak-to-keycloak-idp.md)
* [Keycloak Upgrade Guide](keycloak.md)
