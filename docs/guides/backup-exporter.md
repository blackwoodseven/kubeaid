# Backup Exporter

The `obmondo-backup-exporter` chart deploys a Prometheus exporter that monitors the health of your
backup infrastructure. It exposes metrics and ships PrometheusRule alerts for both **Velero** and
**PostgreSQL** backups.

## What It Monitors

| Backup System | Alert | Fires When |
| ------------- | ----- | ---------- |
| PostgreSQL | `PostgresBackupExporterJobFailed` | A PostgreSQL backup job reports an error (`backup_exporter_postgres_error == 1`) |
| Velero | `VeleroBackupExporterJobFailed` | A Velero backup job reports an error (`backup_exporter_velero_error == 1`) |

Both alerts default to `critical` severity and fire after 5 minutes. These are configurable via the
values file.

## Deployment

The chart is deployed via ArgoCD like any other KubeAid application. Key values to configure:

```yaml
# Enable Prometheus alerting rules
prometheusRule:
  enabled: true
  postgres:
    enabled: true
    namespace: monitoring        # Where the PrometheusRule is created
    severity: critical
    alertForDuration: 5m
  velero:
    enabled: true
    namespace: monitoring
    severity: critical
    alertForDuration: 5m
```

The exporter also ships a **ServiceMonitor** for automatic Prometheus scraping and supports
**HorizontalPodAutoscaler** configuration.

## Integration with Existing Monitoring

The backup exporter complements KubeAid's existing monitoring stack:

- **kube-prometheus** scrapes the exporter's metrics via the ServiceMonitor
- **Alertmanager** routes the backup failure alerts to your configured notification channels
- **Grafana** can visualise the backup health metrics alongside your cluster dashboards

## See Also

- [Monitoring](../monitoring.md) - overall monitoring architecture
- [Backup & Restore](../operations/backup-restore.md) - disaster recovery procedures
