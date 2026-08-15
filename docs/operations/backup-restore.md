# Backup and Restore Strategy Overview

This document provides a technical overview of the backup mechanisms implemented across Kubernetes clusters managed
by our DevOps team.

---

## 1. Persistent Volume (PV) Backup and Restore with Velero

We use Velero to orchestrate backups of Persistent Volume Claims (PVCs) in Kubernetes.

- [Triggering manual backups using existing schedule](../../argocd-helm-charts/velero/README.md#triggering-manual-backups)
- [Restoring from backups](../../argocd-helm-charts/velero/README.md#restoring-using-existing-backups)

---

## 2. Sealed Secrets Key Backups

- To preserve the ability to decrypt sealed secrets, we automate the backup of the controller’s private key.
- [Backup and Restore documentation](../../argocd-helm-charts/sealed-secrets/README.md#how-to-backup-and-restore-sealed-secrets)

---

## 3. Logical Database Backups

We use logical dumps for databases such as PostgreSQL and MongoDB to ensure portability and integrity.

### PostgreSQL
  
- [CNPG backup and restore documentation](../../argocd-helm-charts/cloudnative-pg/readme.md#backup-and-recovery)
- [Zalando postgres operator backup and restore documentation](../../argocd-helm-charts/postgres-operator/README.md#backup)

### MongoDB

- The chart was renamed from `mongodb-operator` to
  [`mongodb-kubernetes`](../../argocd-helm-charts/mongodb-kubernetes/README.md); its README is now a migration guide
  (MCO to MCK) and doesn't cover backup/restore yet. Documentation pending.

---

## 4. Checking Backup Health

The [backup-exporter](../../argocd-helm-charts/backup-exporter/) chart reads object storage directly and reports
whether PostgreSQL (CNPG logical and WAL), Velero, MongoDB, and Sealed Secrets backups actually landed. Check status
with:

```bash
kubeaid-cli backup status
```

See the [backup status docs](https://github.com/Obmondo/kubeaid-cli/blob/main/docs/backup-status.md) for the
metrics reference, JSON output (`-o json`), and alerting behavior.

## Summary

| Component           | Tool/Method            | Target Storage                     |
|---------------------|------------------------|------------------------------------|
| PVCs                | Velero + CSI Snapshots | Azure Blob / S3 Compatible Storage |
| Sealed Secret Keys  | CronJob + GZIP         | Azure Blob / S3 Compatible Storage |
| PostgreSQL / MongoDB| Logical dump scripts   | Azure Blob / S3 Compatible Storage |
