# MariaDB Operator

Wrapper around the upstream [mariadb-operator](https://mariadb-operator.github.io/mariadb-operator) Helm
chart (v26.6.0). Installs the operator and CRDs (`MariaDB`, `Database`, `User`, `Grant`, `Backup`, and more)
that let applications provision and manage MariaDB instances declaratively.

## Why it's in KubeAid

Several KubeAid application charts run MariaDB. Where a chart's `externalMariadb.enabled` flag is set, it
creates a `k8s.mariadb.com/v1alpha1` `MariaDB` custom resource instead of relying on the bundled Bitnami
MariaDB sub-chart - `friendica`, `castopod`, `matomo`, and `erpnext` all ship an
`externalMariadb`-gated `MariaDB` resource today. This operator is the prerequisite for that resource to
reconcile into a running database.

## Prerequisites

- cert-manager, for the operator's admission webhook TLS certificate (see below).

## Key values / KubeAid-specific configuration

| Value | Description | Default |
|---|---|---|
| `mariadb-operator.metrics.enabled` | Enable operator/instance metrics for Prometheus | `true` |
| `mariadb-operator.webhook.certificate.certManager` | Issue the webhook TLS cert via cert-manager instead of the operator's self-signed default | `true` |

## Operational notes

- Application charts that consume this operator opt in per-instance via their own `externalMariadb.enabled`
  value; this chart only installs the operator and CRDs, it does not create any `MariaDB` instances itself.

## Docs links

- [mariadb-operator docs](https://mariadb-operator.github.io/mariadb-operator/)
- [`MariaDB` CRD reference](https://mariadb-operator.github.io/mariadb-operator/latest/mariadb/)
- Consumers: [`friendica`](../friendica), [`castopod`](../castopod), [`matomo`](../matomo), [`erpnext`](../erpnext)
