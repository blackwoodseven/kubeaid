# Open-Xchange App Suite

OX App Suite is an enterprise email, calendar and collaboration platform.

This chart wraps the upstream `appsuite` Helm chart and adds Traefik ingress support.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Minimal values](#minimal-values)
- [Traefik ingress](#traefik-ingress)
- [Mail configuration](#mail-configuration)
  - [Production — Mailcow](#production--mailcow)
  - [Production — generic IMAP/SMTP](#production--generic-imapsmtp)
  - [Testing — Dovecot + MailHog stub](#testing--dovecot--mailhog-stub)
- [Keycloak OIDC](#keycloak-oidc)
- [User provisioning](#user-provisioning)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- External MariaDB/MySQL database
- Redis (bundled via `core-mw.redis`)
- Traefik as ingress controller (with `traefik-cert-manager` IngressClass)
- A wildcard TLS secret in the `traefik` namespace
- An IMAP server — **required**. OX connects to IMAP on every login to read the folder namespace. If IMAP is unreachable, login fails with `Some mandatory configuration could not be loaded. (namespace)`.

---

## Minimal values

```yaml
traefik:
  enabled: true
  host: ox.example.com

appsuite:
  ingress:
    enabled: true
    ingressClassName: traefik-cert-manager
    annotations:
      traefik.ingress.kubernetes.io/router.entrypoints: websecure
      traefik.ingress.kubernetes.io/router.tls: "true"
    appsuite:
      hosts:
        - ox.example.com
    dav:
      hosts:
        - ox.example.com
    tls:
      enabled: false   # Traefik wildcard handles TLS
    routes:
      http-api-routes-appsuite-api:
        annotations:
          traefik.ingress.kubernetes.io/router.priority: "200"
      http-api-routes-ajax:
        annotations:
          traefik.ingress.kubernetes.io/router.priority: "200"
      http-api-routes-api:
        annotations:
          traefik.ingress.kubernetes.io/router.priority: "200"

  core-mw:
    mysql:
      host: "mariadb.open-xchange.svc.cluster.local"
      port: "3306"
      database: "open_xchange"
      existingSecret: ox-core-mw-mysql-secret
      auth:
        user: "openexchange"
```

---

## Traefik ingress

The upstream appsuite chart generates Ingresses with nginx-style path regex (`(.*)`) that Traefik
does not evaluate. The `routes` priority annotations in the minimal values above fix API path
routing for most cases.

This chart also provides an `IngressRoute` template that:
- Explicitly routes API paths (`/appsuite/api`, `/ajax`, `/api`) at priority 200
- Redirects the bare root `/` to the OIDC login flow automatically

Enable it via:

```yaml
traefik:
  enabled: true
  host: ox.example.com
  ingressRoute:
    enabled: true   # default: true
```

With `ingressRoute.enabled: true`, visiting `https://ox.example.com/` redirects directly to
Keycloak without showing the local login form first.

---

## Mail configuration

OX **always** connects to IMAP on login. There is no way to skip this step.

### Production — Mailcow

[Mailcow](https://mailcow.email) provides Dovecot IMAP + Postfix SMTP in one stack and is the
recommended mail backend.

**Step 1 — Create mailboxes in Mailcow**

Each OX user needs a matching mailbox in Mailcow. Use the Mailcow admin UI or API:

```bash
curl -X POST https://<mailcow-host>/api/v1/add/mailbox \
  -H "X-API-Key: <mailcow-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "local_part": "rishi",
    "domain": "example.com",
    "password": "<password>",
    "quota": "1024",
    "active": "1"
  }'
```

**Step 2 — Configure OX to use Mailcow**

```yaml
appsuite:
  core-mw:
    properties:
      com.openexchange.mail.mailServer: "<mailcow-host>:993"
      com.openexchange.mail.mailServerSource: "global"
      com.openexchange.mail.loginSource: "mail"
      com.openexchange.mail.passwordSource: "global"
      com.openexchange.mail.masterPassword: "<mailcow-master-password>"
      com.openexchange.mail.useSSL: "true"
      com.openexchange.mail.transportServer: "<mailcow-host>:587"
      com.openexchange.mail.transportServerSource: "global"
      com.openexchange.mail.transport.useSSL: "true"
      com.openexchange.imap.requireTls: "true"
      com.openexchange.smtp.requireTls: "true"
```

**`loginSource: mail`** — OX sends the full email address (e.g. `rishi@example.com`) as the IMAP
username, which is what Mailcow expects.

**`passwordSource: global` + `masterPassword`** — required for OIDC users since they have no
session password. The master password must be configured in Mailcow as an admin override password.

### Production — generic IMAP/SMTP

```yaml
appsuite:
  core-mw:
    properties:
      com.openexchange.mail.mailServer: "imap.example.com:993"
      com.openexchange.mail.mailServerSource: "global"
      com.openexchange.mail.loginSource: "mail"
      com.openexchange.mail.passwordSource: "session"
      com.openexchange.mail.useSSL: "true"
      com.openexchange.mail.transportServer: "smtp.example.com:587"
      com.openexchange.mail.transportServerSource: "global"
      com.openexchange.mail.transport.useSSL: "true"
      com.openexchange.imap.requireTls: "true"
      com.openexchange.smtp.requireTls: "true"
```

Use `passwordSource: session` only when users log in with a password (not OIDC).

### Testing — Dovecot + MailHog stub

For testing without a real mail server, deploy Dovecot (IMAP stub) and MailHog (SMTP stub).
Dovecot accepts any username with password `admin`. MailHog captures sent mail without delivering it.

Deploy both from `k8s/<cluster>/dovecot/` in the config repo, then configure OX:

```yaml
appsuite:
  core-mw:
    properties:
      com.openexchange.mail.mailServer: "dovecot.open-xchange.svc.cluster.local:143"
      com.openexchange.mail.mailServerSource: "global"
      com.openexchange.mail.loginSource: "name"
      com.openexchange.mail.passwordSource: "global"
      com.openexchange.mail.masterPassword: "admin"
      com.openexchange.mail.useSSL: "false"
      com.openexchange.mail.transportServer: "mailhog.open-xchange.svc.cluster.local:1025"
      com.openexchange.mail.transportServerSource: "global"
      com.openexchange.mail.transport.useSSL: "false"
      com.openexchange.imap.enableTls: "false"
      com.openexchange.imap.requireTls: "false"
      com.openexchange.smtp.requireTls: "false"
      com.openexchange.capabilities.hardcoded.deny: "mailfilter"
```

**Why `mailfilter` denied:** OX tries to connect to Sieve (port 4190) on login. The Dovecot stub
has no Sieve, so denying this capability prevents a 500 error.

MailHog web UI: `http://mailhog.open-xchange.svc.cluster.local:8025`

---

## Keycloak OIDC

**Step 1 — Register a client in Keycloak**

- Client ID: `open-xchange`
- Access Type: `confidential`
- Valid Redirect URIs: `https://ox.example.com/appsuite/*`

Copy the client secret from the `Credentials` tab.

**Step 2 — Seal the client secret**

```yaml
# oidc.properties — seal this as ox-oidc-secret
anywhere:
  com.openexchange.oidc.clientSecret: "<client-secret>"
```

```yaml
appsuite:
  core-mw:
    existingPropertiesSecret: ox-oidc-secret
```

**Step 3 — Add OIDC properties**

```yaml
appsuite:
  core-mw:
    properties:
      com.openexchange.oidc.enabled: "true"
      com.openexchange.oidc.startDefaultBackend: "true"
      com.openexchange.oidc.opIssuer: "https://keycloak.example.com/auth/realms/<realm>"
      com.openexchange.oidc.opAuthorizationEndpoint: "https://keycloak.example.com/auth/realms/<realm>/protocol/openid-connect/auth"
      com.openexchange.oidc.opTokenEndpoint: "https://keycloak.example.com/auth/realms/<realm>/protocol/openid-connect/token"
      com.openexchange.oidc.opJwkSetEndpoint: "https://keycloak.example.com/auth/realms/<realm>/protocol/openid-connect/certs"
      com.openexchange.oidc.clientId: "open-xchange"
      com.openexchange.oidc.rpRedirectURIAuth: "https://ox.example.com/appsuite/api/oidc/auth"
      com.openexchange.oidc.userLookupClaim: "email"
      com.openexchange.oidc.userLookupNamePart: "local-part"
      com.openexchange.oidc.contextLookupClaim: "email"
      com.openexchange.oidc.contextLookupNamePart: "domain"
      com.openexchange.secret.secretSource: "<user-id> + '@' + <context-id>"
```

---

## User provisioning

OX requires users to exist in its own database before OIDC login works. OIDC does not auto-create users.

**Add domain → context mapping (once per domain):**

```bash
kubectl -n open-xchange exec open-xchange-mariadb-0 -- \
  mariadb -u openexchange -p<password> open_xchange \
  -e "INSERT IGNORE INTO login2context (login_info, cid) VALUES ('example.com', 1);"
```

**Create a user:**

```bash
kubectl -n open-xchange exec statefulset/open-xchange-core-mw-default -- \
  /opt/open-xchange/sbin/createuser \
  -A <master-admin> -P <master-password> \
  -c 1 \
  -u <username> \
  -e <username>@example.com \
  -p admin \
  -g <firstname> \
  -s <lastname> \
  -d "<Display Name>"
```

---

## Troubleshooting

### `Some mandatory configuration could not be loaded. (namespace)`

OX cannot connect to IMAP during login.

```bash
# Test reachability from the OX pod
kubectl -n open-xchange exec open-xchange-core-mw-default-0 -- \
  nc -zv <imap-host> <port>
```

Check: `mailServer` is correct, `requireTls: false` if server has no STARTTLS, `mailEnabled = 1`
in the `user` table (setting it to `0` fully disables the account).

### `Forbidden — User X in context Y is not enabled`

`mailEnabled = 0` in the `user` table disables the account entirely — not just mail. Fix:

```bash
kubectl -n open-xchange exec open-xchange-mariadb-0 -- \
  mariadb -u openexchange -p<password> oxdatabase_4 \
  -e "UPDATE user SET mailEnabled=1 WHERE cid=1 AND mail='user@example.com';"
```

### Too many redirects after OIDC login

The Traefik redirect rule is matching `/appsuite/` after OX redirects back post-login. Ensure
the IngressRoute only redirects the bare `/` path — not `/appsuite/` or `/appsuite`.

### CertificateRequest stuck, cert not renewing

Delete the stuck `CertificateRequest` and its stale next-key secret — cert-manager retries immediately:

```bash
kubectl -n <namespace> delete certificaterequest <name>
kubectl -n <namespace> delete secret <nextPrivateKeySecretName>
```
