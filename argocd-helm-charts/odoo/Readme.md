# Running Odoo Instances in Kubernetes

We manage configuration of Odoo instances via the `kubeaid-config` repository. For each instance, there is a template file and a values file.

Each Odoo instance has: -

Template file:
`kubeaid-config/k8s/<cluster-name>/argocd-apps/templates/<odoo-cms-name>.yaml`

Values file:
`kubeaid-config/k8s/<cluster-name>/argocd-apps/values-<odoo-cms-name>.yaml`

Example values file: [values.yaml](values.yaml)

## Create a new Odoo Instance

1.  Go to your kubeaid-config repository and copy an existing template and values file to new ones.

2.  Update the values file and template file with the desired configuration.

3.  Access ArgoCD:

    ``` bash
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```

    Get the admin password:

    ``` bash
    kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
    ```

    Open http://localhost:8080 and log in with:

    -   Username: `admin`
    -   Password: output from above command

4.  In ArgoCD UI: go to
    `root application -> sync list -> find the new Odoo instance -> sync`

The new Odoo CMS instance is now running.

## Adding a Hostname/Domain

1.  Open the values file of your instance.

2.  Find the `ingress` section.

3.  Add your domain under the `hostname` field:

    ``` yaml
    ingress:
      enabled: true
      hostname: your-domain.com
    ```

4.  Repeat the ArgoCD sync workflow.

Your domain is now active and pointing to the Odoo CMS.

The values file supports many customization options (e.g., scaling,
resources, storage, secrets).
Update them as needed, then re-sync in ArgoCD to apply changes.

## Backup and Restore

An Odoo deployment uses two different storage layers to persist its data:

1. Odoo native PVC
    - Mounted at `/bitnami/odoo`
    - Stores assets, filestore, `odoo.conf`, and other application-level data

2. PostgreSQL PVC
    - Odoo uses CNPG as its database
    - PostgreSQL maintains its own dedicated PVC for database storage

Both must be backed up and restored together for a consistent recovery.

### Backup

#### Odoo PVC Backup

Velero + S3-compatible backend is used to back up the Odoo native PVC.

- Velero can be configured to store backups in any S3-compatible object store such as:
    - Zenko
    - SeaweedFS
    - AWS S3, MinIO, etc.
- Credentials are provided via Kubernetes secrets.

A velero instance should be present in order to set up backups

### PostgreSQL Backup

CNPG supports **cron-based logical backups** for PostgreSQL.

Logical backups can be enabled using the following values:

```yaml                                                                                                                       
postgres:                                                                                                                     
  logicalbackup:                                                                                                              
    enabled: true                                                                                                             
# additional values as required                                                                                               
```

### Restore

It is recommended to set Odoo replica to 0 to avoid unnecessary errors. also set ```BITNAMI_DEBUG``` environment variable as true while restoring to get detailed logs.

#### Restoring Odoo PVC using velero

To restore velero based backup (odoo PVC) we can simply use velero related commands to restore the PVC.
Here is the [guide](../velero/README.md)

NOTE: After restore, you will face authentication errors in odoo pod where it will not be able to connect to the database. 
It happens because db password in Odoo configuration file and the one in secret differs. 
You can simply create a pod to exec into restored PVC and change the password to the one placed in secrets
you need to change passwords in both the files to be 100% safe.

```/opt/bitnami/odoo/conf/odoo.conf```
```/bitnami/odoo/conf/odoo.conf```

#### Restoring Odoo PostgreSQL Backup

For restoring pgsql logical backups, we utilise pgsql read-write service.

To restore pgsql logical backups we can follow these steps:

1. retrieve logical backup file from your S3 setup

2. once you have it in place, extract it
```shell
gunzip -c odoo-backup.sql.gz
```

3. Port forward the odoo-pgsql-rw service
```shell
kubectl port-forward svc/odoo-pgsql-rw 5432:5432 -n <namespace>
```

4. Now start the restore process.

```shell
psql -h localhost -U odoo -d odoo -f odoo-backup.sql
```

- The command will prompt for a password.
- The password is stored in the `odoo-pgsql-app` secret in the same namespace.   

PostgreSQL restore time depends on size so it varies a lot
