# GoAlert

Obmondo-authored chart (no vendored `charts/goalert` - only a `kubeaid-addons` sub-chart for provisioning
Postgres, plus local `templates/`) for [GoAlert](https://github.com/target/goalert) `v0.32.0`: open-source
on-call scheduling, automated escalations, and notifications.

## Why it's in KubeAid

Provides on-call scheduling and escalation as a standalone service, independent of Grafana - an alternative
to the [`oncall`](../oncall) chart for clusters that don't want on-call tied to a Grafana install.

## Prerequisites

- A `GOALERT_DATA_ENCRYPTION_KEY` sealed Secret - encrypts data at rest, must be backed up, and must never
  change once set.
- CloudNativePG - Postgres is provisioned via `global.postgresql` (through `kubeaid-addons`); the bundled
  `postgresql` sub-chart is disabled.

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `goalert.dbUrlSecret.name` / `.key` | CNPG secret + key the DB URL is read from | `<instanceName>-pgsql-app` / `fqdn-uri` |
| `goalert.encryptionKeySecret.name` / `.key` | Secret + key holding the data-encryption key | `goalert` / `GOALERT_DATA_ENCRYPTION_KEY` |
| `postgresql.enabled` | Bundled Postgres sub-chart | `false` |
| `global.postgresql.enabled` | Provision the CNPG cluster via `kubeaid-addons` | `true` |
| `global.postgresql.instanceName` | CNPG instance name (→ cluster `goalert-pgsql`) | `goalert` |
| `global.postgresql.disableCpuLimit` | No CPU limit on the Postgres cluster | `true` |
| `ingress.enabled` | Expose GoAlert externally | `false` |
| `resources` | Memory-limited only, no CPU limit by policy | 50m/128Mi requests, 512Mi limit |
| `pgchecker.enabled` | Init container that blocks startup until Postgres accepts connections | `true` |

## Operational notes

- Create the `GOALERT_DATA_ENCRYPTION_KEY` SealedSecret before first sync:

  ```bash
  NS=goalert   # your target namespace
  ENC_KEY="$(openssl rand -base64 32)"

  kubectl create secret generic goalert -n "$NS" \
    --from-literal=GOALERT_DATA_ENCRYPTION_KEY="$ENC_KEY" \
    --dry-run=client -o yaml \
  | kubeseal --format yaml > goalert-sealed-secret.yaml
  ```

- GoAlert has no default login - after first sync, create the first admin from the CLI inside the pod:
  `kubectl -n <ns> exec -it deploy/goalerts -- goalert add-user --admin --user admin`. Create real per-person
  admin accounts from the UI afterward and remove this bootstrap one.
- Reach the UI via `ingress.*` or by port-forwarding the service on `:8081`.

## Docs links

- [GoAlert upstream](https://github.com/target/goalert)
- Related: [`oncall`](../oncall)
