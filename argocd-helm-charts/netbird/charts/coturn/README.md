# coturn

![Version: 10.1.0](https://img.shields.io/badge/Version-10.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.18.0](https://img.shields.io/badge/AppVersion-4.18.0-informational?style=flat-square)

A Helm chart to deploy coturn

**Homepage:** <https://codeberg.org/open-engineering/coturn-chart>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| jessebot |  | <https://codeberg.org/jessebot/> |

## Source Code

* <https://codeberg.org/open-engineering/coturn-chart>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://cloudnative-pg.github.io/charts | cnpg(cluster) | 0.8.1 |
| https://percona.github.io/percona-helm-charts | mysql(pxc-db) | 1.20.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| certificate.enabled | bool | `false` | Enables auto issuing certificates over cert-manager certificates https://cert-manager.io/docs/concepts/certificate/ |
| certificate.issuerName | string | `"letsencrypt-staging"` | name of cert-manager issuer to use for cert generation. change to production issuer when you're stable |
| certificate.secret | string | `"turn-tls"` | name of secret to create for ssl cert |
| cnpg.backups.destinationPath | string | `"s3://coturn-db"` | this should be replace with your bucket, if your bucket is not called coturn |
| cnpg.backups.enabled | bool | `false` | enable backups, recommended |
| cnpg.backups.endpointURL | string | `"http://seaweedfs-s3.coturn.svc.cluster.local:8333"` | this is just an example, but you could use any s3 |
| cnpg.backups.provider | string | `"s3"` | you can use any supported provider, but we find s3 handy |
| cnpg.backups.retentionPolicy | string | `"2d"` | retain as many days as you'd like |
| cnpg.backups.s3.accessKey | string | `"ACCESS_KEY_ID"` |  |
| cnpg.backups.s3.bucket | string | `"coturn-db"` |  |
| cnpg.backups.s3.region | string | `"auto"` |  |
| cnpg.backups.s3.secretKey | string | `"ACCESS_SECRET_KEY"` |  |
| cnpg.backups.scheduledBackups[0].backupOwnerReference | string | `"self"` |  |
| cnpg.backups.scheduledBackups[0].method | string | `"barmanObjectStore"` |  |
| cnpg.backups.scheduledBackups[0].name | string | `"coturn-db-backup"` |  |
| cnpg.backups.scheduledBackups[0].schedule | string | `"0 0 0 * * *"` |  |
| cnpg.backups.secret.create | bool | `false` |  |
| cnpg.backups.secret.name | string | `"s3-db-credentials"` |  |
| cnpg.backups.wal.compression | string | `"gzip"` |  |
| cnpg.backups.wal.encryption | string | `"AES256"` |  |
| cnpg.backups.wal.maxParallel | int | `8` |  |
| cnpg.certificates | object | `{}` | cert configuration for this postgresql cluster |
| cnpg.cluster.annotations."cnpg.io/skipEmptyWalArchiveCheck" | string | `"enabled"` | allow restoring to existing s3 buckets |
| cnpg.cluster.initdb.database | string | `"coturn"` | name of the database for coturn |
| cnpg.cluster.initdb.owner | string | `"coturn"` | name of the owner of the database for coturn |
| cnpg.cluster.initdb.secret.name | string | `"coturn-db-secret"` |  |
| cnpg.cluster.instances | int | `2` | how many instances to deploy for this postgres cluster |
| cnpg.cluster.logLevel | string | `"warn"` | logging level |
| cnpg.cluster.monitoring.enabled | bool | `false` | enable monitoring |
| cnpg.cluster.monitoring.podMonitor.enabled | bool | `true` | enable a promtheus podMonitor resource |
| cnpg.cluster.postgresql.pg_hba | list | `["host all all 0.0.0.0/0 md5"]` | pg_hba config for the postgres cluster |
| cnpg.cluster.storage.size | string | `"10Gi"` | size of the PVCs that CNPG will create |
| cnpg.cluster.storage.storageClass | string | `"local-path"` | storageClass for the PVCs CNPG will create |
| cnpg.enabled | bool | `false` | Whether to deploy the Cloud Native Postgresql Cluster sub chart If cnpg.enabled is set to true, externalDatabase.enabled must be set to false else if externalDatabase.enabled is set to true, cnpg.enabled must be set to false. NOTE: if using this Cluster chart, you must already have Cloud Native PostgreSQL Operator installed! |
| cnpg.fullnameOverride | string | `"coturn-postgres"` |  |
| cnpg.mode | string | `"standalone"` | Cluster mode of operation. Available modes: * `standalone` - default mode. Creates new or updates an existing CNPG cluster. * `replica` - Creates a replica cluster from an existing CNPG cluster. * `recovery` - Same as standalone but creates a cluster from a backup, object store or via pg_basebackup. |
| cnpg.name | string | `"coturn-postgres"` |  |
| cnpg.type | string | `"postgresql"` | this should always be postgresql as that's all we support from this chart |
| cnpg.version.postgresql | string | `"18"` | PostgreSQL major version to use |
| containerSecurityContext.allowPrivilegeEscalation | bool | `false` | allow priviledged access |
| containerSecurityContext.capabilities.add | list | `["NET_BIND_SERVICE"]` | linux cabilities to allow for the coturn k8s pod |
| containerSecurityContext.capabilities.drop | list | `["ALL"]` | linux cabilities to disallow for the coturn k8s pod |
| containerSecurityContext.enabled | bool | `true` | Enables Security Context |
| containerSecurityContext.readOnlyRootFilesystem | bool | `false` | allow modificatin to root filesystem |
| coturn.auth.existingSecret | string | `""` | existing secret with keys username/password for coturn |
| coturn.auth.password | string | `""` | password for the main user of the turn server |
| coturn.auth.secretKeys.password | string | `"password"` | key in existing secret for turn server user's password |
| coturn.auth.secretKeys.staticAuthSecret | string | `""` | key in existing secret for coturn static-auth-secret |
| coturn.auth.secretKeys.username | string | `"username"` | key in existing secret for turn server user |
| coturn.auth.staticAuthSecret | string | `""` | 'Static' authentication secret value (a string) for TURN REST API only. If not set, then the turn server will try to use the 'dynamic' value in the turn_secret table in the user database (if present). The database-stored  value can be changed on-the-fly by a separate program, so this is why that mode is considered 'dynamic'. |
| coturn.auth.username | string | `"coturn"` | username for the main user of the turn server |
| coturn.extraEnvVars | list | `[]` | Extra environment variables to pass to the Coturn container |
| coturn.extraTurnserverConfiguration | string | `"verbose\n"` | extra configuration for turnserver.conf |
| coturn.initContainer.image.repository | string | `"mikefarah/yq"` | registry and repository for init container config generator image |
| coturn.initContainer.image.tag | string | `"latest"` | tag for init container config generator image |
| coturn.listeningIP | string | `"0.0.0.0"` | coturn's listening IP address |
| coturn.logFile | string | `"stdout"` | set the logfile. Defaults to stdout for use with kubectl logs |
| coturn.ports.listening | int | `3478` | insecure listening port |
| coturn.ports.max | int | `65535` | maximum ephemeral port for coturn |
| coturn.ports.min | int | `49152` | minimum ephemeral port for coturn |
| coturn.ports.tlsListening | int | `5349` | secure listening port |
| coturn.realm | string | `"turn.example.com"` | hostname for the coturn server realm |
| dbReadiness.image.repository | string | `"postgres"` | container registry and repo for database readiness docker image change this if using mysql! |
| dbReadiness.image.tag | string | `"18-alpine"` | container tag for coturn database readiness docker image change this if using mysql! |
| deployment.affinity | object | `{}` | affinity rules for the coturn pods |
| deployment.dnsPolicy | string | `"ClusterFirst"` |  |
| deployment.hostNetwork | bool | `false` |  |
| deployment.nodeSelector | object | `{}` | node selector for the coturn pods. With hostNetwork this decides which node IPs answer STUN/TURN, so it has to match the stun/turn DNS records |
| deployment.tolerations | list | `[]` | tolerations for the coturn pods, e.g. to run on tainted control planes |
| deployment.type | string | `"Deployment"` |  |
| externalDatabase.database | string | `""` | database to create, ignored if existingSecret is passed in |
| externalDatabase.enabled | bool | `false` | enables the use of postgresql instead of the default sqlite to use the bundled subchart, enable this, and postgresql.enable |
| externalDatabase.existingSecret | string | `""` | name of existing Secret to use for postgresql credentials |
| externalDatabase.hostname | string | `""` | required if externalDatabase.enabled: true and postgresql.enabled: false |
| externalDatabase.password | string | `""` | password for database, ignored if existingSecret is passed in |
| externalDatabase.secretKeys.database | string | `""` | key in existing Secret to use for the database name |
| externalDatabase.secretKeys.hostname | string | `""` | key in existing Secret to use for the db's hostname |
| externalDatabase.secretKeys.password | string | `""` | key in existing Secret to use for db user's password |
| externalDatabase.secretKeys.username | string | `""` | key in existing Secret to use for the db user |
| externalDatabase.type | string | `"postgresql"` | Currently postgresql and mysql are supported. |
| externalDatabase.username | string | `""` | username for database, ignored if existingSecret is passed in |
| image.pullPolicy | string | `"IfNotPresent"` | image pull policy, set to Always if using image.tag: latest |
| image.repository | string | `"coturn/coturn"` | container registry and repo for coturn docker image |
| image.tag | string | `""` | docker tag for coturn server |
| labels | object | `{"component":"coturn"}` | Coturn specific labels |
| mysql.backup.enabled | bool | `false` | it's recommended to turn on backups, but they're off by default for CI purposes |
| mysql.backup.pitr.enabled | bool | `false` |  |
| mysql.backup.pitr.resources.limits | object | `{}` |  |
| mysql.backup.pitr.resources.requests | object | `{}` |  |
| mysql.backup.pitr.storageName | string | `"s3-binlogs"` |  |
| mysql.backup.pitr.timeBetweenUploads | int | `600` |  |
| mysql.backup.pitr.timeoutSeconds | int | `60` |  |
| mysql.backup.schedule | list | `[]` | backups schedule. example: - name: "daily-coturn-mysql-backup"   schedule: ""   retention:     type: "count"     count: 10     # needs to be disabled when using pitr     deleteFromStorage: true   storageName: s3 |
| mysql.backup.storages.s3.affinity.antiAffinityTopologyKey | string | `"none"` | set this to something else if deploying to more than one node |
| mysql.backup.storages.s3.labels.backupWorker | string | `"True"` |  |
| mysql.backup.storages.s3.resources.requests.cpu | string | `"600m"` |  |
| mysql.backup.storages.s3.resources.requests.memory | string | `"1G"` |  |
| mysql.backup.storages.s3.s3.bucket | string | `"coturn-db"` |  |
| mysql.backup.storages.s3.s3.checksumAlgorithm | string | `"SHA256"` |  |
| mysql.backup.storages.s3.s3.credentialsSecret | string | `"s3-db-credentials"` |  |
| mysql.backup.storages.s3.s3.endpointUrl | string | `""` |  |
| mysql.backup.storages.s3.s3.forcePathStyle | bool | `true` |  |
| mysql.backup.storages.s3.s3.prefix | string | `"/"` |  |
| mysql.backup.storages.s3.s3.region | string | `"auto"` |  |
| mysql.backup.storages.s3.type | string | `"s3"` |  |
| mysql.backup.storages.s3.verifyTLS | bool | `true` |  |
| mysql.crVersion | string | `"1.20.0"` |  |
| mysql.enableCRValidationWebhook | bool | `false` |  |
| mysql.enableVolumeExpansion | bool | `false` |  |
| mysql.enabled | bool | `false` | enable deploying the bundled pxc-db sub-chart. Requires the Percona PXC Operator learn more here: https://github.com/percona/percona-helm-charts/tree/main/charts/pxc-db |
| mysql.finalizers[0] | string | `"percona.com/delete-pxc-pods-in-order"` |  |
| mysql.fullnameOverride | string | `"coturn-mysql"` |  |
| mysql.haproxy.affinity.antiAffinityTopologyKey | string | `"none"` | set this to something else if you're deploying to more than one node |
| mysql.haproxy.enabled | bool | `true` |  |
| mysql.haproxy.gracePeriod | int | `30` |  |
| mysql.haproxy.livenessDelaySec | int | `200` |  |
| mysql.haproxy.livenessProbes.failureThreshold | int | `4` |  |
| mysql.haproxy.livenessProbes.initialDelaySeconds | int | `60` |  |
| mysql.haproxy.livenessProbes.periodSeconds | int | `30` |  |
| mysql.haproxy.livenessProbes.successThreshold | int | `1` |  |
| mysql.haproxy.livenessProbes.timeoutSeconds | int | `5` |  |
| mysql.haproxy.podDisruptionBudget.maxUnavailable | int | `1` |  |
| mysql.haproxy.readinessDelaySec | int | `15` |  |
| mysql.haproxy.readinessProbes.failureThreshold | int | `3` |  |
| mysql.haproxy.readinessProbes.initialDelaySeconds | int | `15` |  |
| mysql.haproxy.readinessProbes.periodSeconds | int | `5` |  |
| mysql.haproxy.readinessProbes.successThreshold | int | `1` |  |
| mysql.haproxy.readinessProbes.timeoutSeconds | int | `1` |  |
| mysql.haproxy.resources.limits | object | `{}` |  |
| mysql.haproxy.resources.requests.cpu | string | `"600m"` |  |
| mysql.haproxy.resources.requests.memory | string | `"1G"` |  |
| mysql.haproxy.size | int | `2` |  |
| mysql.logcollector.enabled | bool | `true` |  |
| mysql.logcollector.resources.limits | object | `{}` |  |
| mysql.logcollector.resources.requests.cpu | string | `"200m"` |  |
| mysql.logcollector.resources.requests.memory | string | `"100M"` |  |
| mysql.nameOverride | string | `"coturn-mysql"` |  |
| mysql.pause | bool | `false` |  |
| mysql.pmm.enabled | bool | `false` |  |
| mysql.proxysql.enabled | bool | `false` |  |
| mysql.pxc.affinity.antiAffinityTopologyKey | string | `"none"` | update this to something else if you're not running this on a single node |
| mysql.pxc.autoRecovery | bool | `true` |  |
| mysql.pxc.certManager | bool | `true` | disable Helm creating TLS certificates if you want to let the operator request certificates from cert-manager |
| mysql.pxc.configuration | string | `"[mysqld]\npxc_strict_mode=PERMISSIVE\n"` |  |
| mysql.pxc.gracePeriod | int | `600` |  |
| mysql.pxc.livenessDelaySec | int | `200` |  |
| mysql.pxc.livenessProbes.failureThreshold | int | `10` |  |
| mysql.pxc.livenessProbes.initialDelaySeconds | int | `50` |  |
| mysql.pxc.livenessProbes.periodSeconds | int | `10` |  |
| mysql.pxc.livenessProbes.successThreshold | int | `1` |  |
| mysql.pxc.livenessProbes.timeoutSeconds | int | `10` |  |
| mysql.pxc.persistence.accessMode | string | `"ReadWriteOnce"` |  |
| mysql.pxc.persistence.enabled | bool | `true` |  |
| mysql.pxc.persistence.size | string | `"8Gi"` |  |
| mysql.pxc.persistence.storageClass | string | `""` | percona data Persistent Volume Storage Class |
| mysql.pxc.podDisruptionBudget.maxUnavailable | int | `1` |  |
| mysql.pxc.readinessDelaySec | int | `15` |  |
| mysql.pxc.readinessProbes.failureThreshold | int | `5` |  |
| mysql.pxc.readinessProbes.initialDelaySeconds | int | `15` |  |
| mysql.pxc.readinessProbes.periodSeconds | int | `30` |  |
| mysql.pxc.readinessProbes.successThreshold | int | `1` |  |
| mysql.pxc.readinessProbes.timeoutSeconds | int | `15` |  |
| mysql.pxc.resources.limits | object | `{}` |  |
| mysql.pxc.resources.requests.cpu | string | `"600m"` |  |
| mysql.pxc.resources.requests.memory | string | `"1G"` |  |
| mysql.pxc.size | int | `2` |  |
| mysql.tls.SANs | list | `["coturn-mysql-pxc-0.coturn.svc.cluster.local","coturn-mysql-pxc-1.coturn.svc.cluster.local"]` | be sure to update these to your namespace |
| mysql.tls.caValidityDuration | string | `"26280h"` |  |
| mysql.tls.certValidityDuration | string | `"2160h"` |  |
| mysql.tls.enabled | bool | `true` | enable TLS, requires certmanager |
| mysql.tls.issuerConf.group | string | `"cert-manager.io"` |  |
| mysql.tls.issuerConf.kind | string | `"ClusterIssuer"` |  |
| mysql.tls.issuerConf.name | string | `"mysql-selfsigned-issuer"` | be sure to update this to your certmanager ClusterIssuer |
| mysql.unsafeFlags.pxcSize | bool | `true` |  |
| mysql.updateStrategy | string | `"SmartUpdate"` | can also be: RollingUpdate |
| mysql.upgradeOptions.apply | string | `"disabled"` |  |
| mysql.upgradeOptions.schedule | string | `"0 4 * * *"` |  |
| mysql.users[0].dbs[0] | string | `"coturn"` |  |
| mysql.users[0].grants[0] | string | `"ALTER"` |  |
| mysql.users[0].grants[1] | string | `"CREATE"` |  |
| mysql.users[0].grants[2] | string | `"DELETE"` |  |
| mysql.users[0].grants[3] | string | `"DROP"` |  |
| mysql.users[0].grants[4] | string | `"INDEX"` |  |
| mysql.users[0].grants[5] | string | `"INSERT"` |  |
| mysql.users[0].grants[6] | string | `"SELECT"` |  |
| mysql.users[0].grants[7] | string | `"UPDATE"` |  |
| mysql.users[0].grants[8] | string | `"REFERENCES"` |  |
| mysql.users[0].grants[9] | string | `"CREATE VIEW"` |  |
| mysql.users[0].name | string | `"coturn"` |  |
| mysql.users[0].passwordSecretRef.key | string | `"password"` |  |
| mysql.users[0].passwordSecretRef.name | string | `"coturn-db-secret"` |  |
| mysql.users[0].withGrantOption | bool | `true` |  |
| nameOverride | string | `""` | different name for the helm release |
| podSecurityContext.enabled | bool | `true` | Enables Pod Security Context |
| podSecurityContext.fsGroup | int | `1000` | all processes of the container are also part of the supplementary groupID |
| podSecurityContext.runAsGroup | int | `1000` | for all Containers in the Pod, all processes run w/ this GroupID |
| podSecurityContext.runAsNonRoot | bool | `true` | for all Containers in the Pod, all processes run as non-root |
| podSecurityContext.runAsUser | int | `1000` | for all Containers in the Pod, all processes run w/ this userID |
| podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` | Filter a process's system calls |
| replicas | int | `1` |  |
| resources | object | `{}` | ref: kubernetes.io/docs/concepts/configuration/manage-resources-containers |
| service.externalTrafficPolicy | string | `"Cluster"` | determines how external traffic is routed to services. Options:   Cluster: mask client source IP   Local: preserve client source IP (requires service type of NodePort or LoadBalancer) |
| service.type | string | `"ClusterIP"` | The type of service to deploy for routing Coturn traffic.   ClusterIP: Recommended for DaemonSet configurations. This will create a              standard Kubernetes service for Coturn within the cluster.              No external networking will be configured as the DaemonSet              will handle binding to each Node's host networking    NodePort:  Recommended for Deployment configurations. This will open              TURN ports on every node and route traffic on these ports to              the Coturn pods. You will need to make sure your cloud              provider supports the cluster config setting,              apiserver.service-node-port-range, as this range must contain              the ports defined above for the service to be created.    LoadBalancer: This was what was originally set for this chart in the                 upstream of this fork, but with no details |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
