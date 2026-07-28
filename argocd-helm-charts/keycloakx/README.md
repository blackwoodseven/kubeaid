# Keycloak Server Setup

Welcome to the Keycloak Helm Chart & Server Setup Documentation.

## Table of Contents (Index)

- [1. Quick Start: Admin Password Generation](#1-quick-start-admin-password-generation)
- [2. Identity Provider (IdP) Integrations](doc/idp-integrations.md)
  - [Google IdP Setup](doc/idp-integrations.md#setup-keycloak-with-google-as-its-identity-provider)
  - [Azure AD IdP Setup](doc/idp-integrations.md#setup-keycloak-with-azure-ad-as-its-identity-provider)
  - [Keycloak-to-Keycloak IdP Brokering](doc/idp-integrations.md#setup-keycloak-as-identity-provider-on-a-keycloak)
  - [External IdP Group Mappers](doc/idp-integrations.md#allow-group-from-external-identity-provider-to-mapper-with-local-keycloak)
- [3. Kubernetes Client & Cluster Integration](doc/kubernetes-integration.md)
  - [Install Krew & oidc-login](doc/kubernetes-integration.md#prerequisites-krew--oidc-login)
  - [Setup Kubernetes Client in Keycloak](doc/kubernetes-integration.md#setup-the-kubernetes-client-in-keycloak)
  - [Setup Client Side (kubectl oidc-login & kubeconfig)](doc/kubernetes-integration.md#setup-the-client-side-kubectl-oidc-login--kubeconfig)
  - [Keycloak Group-based Cluster RBAC](doc/kubernetes-integration.md#create-keycloak-group-based-cluster-rbac-authorization)
- [4. Realm, User & Authentication Management](doc/realm-user-management.md)
  - [Basic Keycloak Setup](doc/realm-user-management.md#basic-keycloak-setup)
  - [User Administration](doc/realm-user-management.md#user-administration)
  - [Default IdP Login Redirector](doc/realm-user-management.md#make-logins-easier-for-the-user)
  - [Client Specific Authentication Flow](doc/realm-user-management.md#set-a-specific-client-to-a-specific-authentication-flow)
  - [Enabling & Forcing YubiKey (WebAuthn) 2FA](doc/realm-user-management.md#enabling-and-forcing-yubikey-webauthn-authentication)
  - [SMTP Email Configuration](doc/realm-user-management.md#configure-keycloak-to-send-email)
- [5. Customization & Extensions](doc/customization-plugins.md)
  - [Custom Login Page Theme](doc/customization-plugins.md#keycloak-custom-login-page)
  - [Webhook Event Plugin](doc/customization-plugins.md#adding-a-webhook-event-plugin-to-keycloak)
- [6. Operations, Disaster Recovery & Maintenance](doc/operations-maintenance.md)
  - [Keycloak Upgrade Guide](doc/keycloak.md)
  - [Disaster Recovery](doc/operations-maintenance.md#disaster-recovery)
  - [Migrating Zalando PGSQL to CNPG Postgres](doc/operations-maintenance.md#migrating-keycloak-from-zalando-to-cnpg)
  - [Troubleshooting](doc/operations-maintenance.md#troubleshooting)
  - [Good Reads & References](doc/operations-maintenance.md#good-reads--references)

---

## 1. Quick Start: Admin Password Generation

Generate Keycloak admin password (fallback user).

> **NOTE:** Do not set the admin password from the WebUI; pass it via environment variable `KEYCLOAK_PASSWORD`.

```bash
openssl rand -base64 14 > ./keycloak_password

# Sealed Secret approach
kubectl create secret generic keycloak-admin -n keycloak --dry-run=client --from-file=KEYCLOAK_PASSWORD=./keycloak_password -o json > mysecret.json
kubeseal --controller-name sealed-secrets --controller-namespace system < mysecret.json > keycloak-admin.json
```

---

## Documentation Modules Overview

Detailed step-by-step guides are organized into focused topics under the [`doc/`](doc/) directory:

| Section | Topic | Description |
| :--- | :--- | :--- |
| 🔐 **IdP Integrations** | [`doc/idp-integrations.md`](doc/idp-integrations.md) | Integrating Google, Azure AD, and Keycloak-to-Keycloak identity brokering. |
| ☸️ **Kubernetes Integration** | [`doc/kubernetes-integration.md`](doc/kubernetes-integration.md) | `oidc-login` setup, `kubeconfig` configuration, and group-based Cluster RBAC. |
| 👥 **Realm & User Management** | [`doc/realm-user-management.md`](doc/realm-user-management.md) | Realm creation, user administration, YubiKey (WebAuthn) 2FA, and SMTP email setup. |
| 🎨 **Customization & Plugins** | [`doc/customization-plugins.md`](doc/customization-plugins.md) | Custom UI login theme and Webhook event plugin configuration. |
| 🛠️ **Operations & Recovery** | [`doc/operations-maintenance.md`](doc/operations-maintenance.md) | Upgrade guide, realm export/import DR, Zalando-to-CNPG DB migration, & troubleshooting. |