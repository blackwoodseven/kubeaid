# backup-exporter

Deploys the [Obmondo Backup Exporter](https://gitea.obmondo.com/EnableIT/backup-exporter) — a
Kubernetes-native exporter that reads object storage directly and reports whether PostgreSQL
(CNPG logical and WAL), Velero, MongoDB, and Sealed Secrets backups actually landed, as
Prometheus metrics and a JSON API. It only ever reads: no Kubernetes object and no S3 object is
ever created, mutated, or deleted.

This chart also carries the `PrometheusRule` alert definitions, so their RPO thresholds come
from the same `max_rpo` values that configure the exporter.

For exporter internals (design, metrics reference, HTTP API, alerting behavior, permissions),
see the [backup-exporter docs](https://gitea.obmondo.com/EnableIT/backup-exporter#documentation).

## Enabling an exporter

Each backup type under `exporter.*` is independently configured. PostgreSQL and Velero are
always active; MongoDB and Sealed Secrets are opt-in (`enabled: false` by default) since not
every cluster runs those backups.

```yaml
exporter:
  postgres:
    max_rpo: 26h
    s3:
      secretName: backup-exporter-s3   # access-key-id, secret-access-key
  velero:
    max_rpo: 26h
    s3:
      url: "https://s3.example.com"
      prefix: ""                       # matches the BSL's objectStorage.prefix, if set
      secretName: backup-exporter-s3   # + region, bucket
  mongodb:
    enabled: true
    s3:
      secretName: backup-exporter-s3
  sealedSecrets:
    enabled: true
    s3:
      bucket: ""                       # must match the sealed-secrets chart's backup.s3Bucket
      endpoint: ""                     # must match the sealed-secrets chart's backup.s3Endpoint
      secretName: backup-exporter-s3
```

`max_rpo` accepts durations like `24h`, `6h`, `30m`; `interval_rate` (default `0.25`) controls
how often each exporter checks relative to `max_rpo`, so a missed backup is caught before the
RPO window fully expires.

## Alerting

Set `prometheusRule.<exporter>.enabled: true` for each backup type you've enabled above — the
rules follow the same opt-in split, so alerts aren't created for an exporter that isn't running.

## Values

See [`values.yaml`](./values.yaml) for the full set of configurable values, including
`image`, `resources`, `serviceMonitor`, and per-exporter S3 credentials.
