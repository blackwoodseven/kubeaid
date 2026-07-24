# goalert

GoAlert - open source on-call scheduling, automated escalations, and notifications. App version `v0.32.0`.

## 1. How to setup

GoAlert reads two values from an existing Secret (default name `goalert`, set via
`goalert.existingSecret.name`):

| Key | What it is |
|---|---|
| `GOALERT_DB_URL` | Postgres connection string |
| `GOALERT_DATA_ENCRYPTION_KEY` | Encrypts data at rest. **Back this up** - losing it makes encrypted data unrecoverable, and it must never change once set. |

### Create it

```bash
NS=goalert   # your target namespace

# 1. A strong data-encryption key (store a copy somewhere safe):
ENC_KEY="$(openssl rand -base64 32)"

# 2. The DB URL. If you're using the CNPG cluster this chart provisions, read it
DB_URL="$(kubectl -n "$NS" get secret goalert-pgsql-app \
            -o jsonpath='{.data.uri}' | base64 -d)?sslmode=require"

# 3. Create the Secret:
kubectl create secret generic goalert -n "$NS" \
  --from-literal=GOALERT_DB_URL="$DB_URL" \
  --from-literal=GOALERT_DATA_ENCRYPTION_KEY="$ENC_KEY"
```

Note: the CNPG cluster (and its `goalert-pgsql-app` secret) must exist first, so sync/deploy the chart once to provision the DB, then create this Secret.

### GitOps (sealed-secrets)

Seal the same object instead of applying it:

```bash
kubectl create secret generic goalert -n "$NS" \
  --from-literal=GOALERT_DB_URL="$DB_URL" \
  --from-literal=GOALERT_DATA_ENCRYPTION_KEY="$ENC_KEY" \
  --dry-run=client -o yaml \
| kubeseal --format yaml > goalert-sealed-secret.yaml
```
(Offline sealing: `kubeseal --cert <controller-cert.pem>`.)

## 2. First admin user

GoAlert has **no default login** - create the first admin with its CLI inside the
pod (it uses `GOALERT_DB_URL` from the Secret above):

```bash
kubectl -n "$NS" exec -it deploy/goalerts -- goalert add-user --admin --user admin
```

Log in at your ingress URL with that account, then create real per-person admin
accounts from the UI and remove this bootstrap one.

## 3. Access

Set `ingress.*` in your values (host, `className`, TLS), or port-forward the
service (`:8081`) to reach the web UI.

## Configuration

| Value | Default | Notes |
|---|---|---|
| `goalert.existingSecret.name` | `goalert` | Secret holding the two keys above |
| `postgresql.enabled` | `false` | Bundled Postgres removed; use CNPG |
| `global.postgresql.enabled` | `true` | Provision the CNPG cluster via kubeaid-addons |
| `global.postgresql.instanceName` | `goalert` | → cluster `goalert-pgsql` |
| `ingress.enabled` | `false` | Set host/class/TLS to expose |
| `resources` | mem-limited | No CPU limit by policy |

Upstream project: https://github.com/target/goalert
