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

## Manually Restore User or Admin Password

For step-by-step instructions, refer to this guide:
[https://cloudpepper.io/docs/odoo-management/recover-odoo-admin-password/](https://cloudpepper.io/docs/odoo-management/recover-odoo-admin-password/)

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

## Recovery / Troubleshooting

### CSS/JS Asset Loading Failures (500 Errors, Broken Styling)

After volume changes, migrations, or pod restarts, Odoo may show:
- 500 errors when loading CSS/JS files
- Website with broken styling (no CSS)
- Blank pages or partial content
- Browser console errors: `Failed to load resource: 500`

#### Understanding the Problem

Odoo stores static assets in a **filestore** directory. The database maintains references to these assets.
When the volume mount path changes or the filestore is empty but the database has stale references, assets fail to load.

**Common Causes:**
| Cause | Description |
|-------|-------------|
| **Volume Path Mismatch** | PVC mounted at different path than Odoo expects |
| **Empty/New Volume** | Database has asset references, but volume is empty |
| **Helm Chart Path Difference** | Bitnami uses `/bitnami/odoo`, official Odoo uses `/var/lib/odoo` |
| **Volume Migration** | Assets lost when switching between storage solutions |

#### Debugging Steps

1. **Check browser console** (`F12` → Network tab) for failed CSS/JS requests

2. **Check pod logs for file errors:**
   ```bash
   kubectl logs <odoo-pod> -n <namespace> | grep -i "file\|asset\|error"
   ```

3. **Verify mount paths inside the container:**
   ```bash
   kubectl exec -it <odoo-pod> -n <namespace> -- /bin/bash
   ls -la /var/lib/odoo/filestore/
   ls -la /bitnami/odoo/
   ```

4. **Check database asset references:**
   ```bash
   kubectl exec -it <postgres-pod> -n <namespace> -- psql -U odoo -d odoo
   SELECT name, store_fname FROM ir_attachment WHERE store_fname IS NOT NULL LIMIT 10;
   ```

#### Resolution

**Option 1: Fix Volume Mount Path**

If using official Odoo images with Bitnami Helm chart, add to your values.yaml:

```yaml
extraVolumeMounts:
  - name: odoo-data
    mountPath: /var/lib/odoo      # Official Odoo path
    subPath: odoo-data

extraVolumes:
  - name: odoo-data
    persistentVolumeClaim:
      claimName: odoo-data-pvc
```

**Option 2: Regenerate Assets**

```bash
kubectl exec <odoo-pod> -n <namespace> -- odoo -d <database> --update=base --stop-after-init
```

**Option 3: Clear Stale Asset References**

If volume is empty but database has stale references:

```sql
-- Connect to PostgreSQL and clear attachment table
TRUNCATE ir_attachment CASCADE;
```

Then restart the pod to trigger reinitialization.

**Option 4: Restore from Backup**

```bash
# Copy filestore backup to pod
kubectl cp ./filestore-backup/ <namespace>/<pod-name>:/var/lib/odoo/filestore/

# Fix permissions
kubectl exec <pod-name> -n <namespace> -- chown -R odoo:odoo /var/lib/odoo/filestore/
```

#### Post-Fix: Clear Browser Cache

After fixing, users MUST clear browser cache:
- **Hard Refresh:** `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
- **Full Clear:** Browser Settings → Clear browsing data → Cached images and files

#### Timeout Issues During Module Installation

If modules take too long to install, increase time limits:

```yaml
command:
  - odoo
  - --limit-time-real=1200
  - --limit-time-cpu=1200
  - --workers=3
```

### Volume Attachment Failures (ContainerCreating)

If Odoo pods are stuck in `ContainerCreating`:

1. **Check events:**
   ```bash
   kubectl describe pod <odoo-pod> -n <namespace>
   ```

2. **Look for volume errors:**
   - `FailedAttachVolume` - Volume attachment timeout
   - `Maximum number of volumes reached` - Hetzner CSI 16-volume limit
   - `Multi-Attach error` - Volume already attached elsewhere

3. **Check volume attachments per node:**
   ```bash
   for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
     count=$(kubectl get volumeattachments -o json | jq -r ".items[] | select(.spec.nodeName==\"$node\") | .metadata.name" | wc -l)
     echo "$node: $count volumes attached"
   done
   ```

See the [Obmondo Wiki - Volume Attachment Issues](https://gitea.obmondo.com/EnableIT/wiki/src/branch/master/procedures/alerts/KubeVolumeAttachmentFailed.md) for detailed resolution strategies.

### Database Connection Errors After Restore

After restoring from backup, you may see authentication errors where Odoo cannot connect to PostgreSQL.

**Cause:** Database password in Odoo config differs from the secret.

**Solution:** Update password in both config files to match the secret:

```bash
# Get password from secret
kubectl get secret odoo-pgsql-app -n <namespace> -o jsonpath="{.data.password}" | base64 -d

# Exec into Odoo pod and update both config files
kubectl exec -it <odoo-pod> -n <namespace> -- /bin/bash
vi /opt/bitnami/odoo/conf/odoo.conf
vi /bitnami/odoo/conf/odoo.conf
```
