# core-mw

![Version: 6.19.7](https://img.shields.io/badge/Version-6.19.7-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 8.48.0](https://img.shields.io/badge/AppVersion-8.48.0-informational?style=flat-square)

App Suite Middleware Core Helm Chart

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Open-Xchange GmbH | <info@open-xchange.com> |  |

## Source Code

* <https://github.com/open-xchange/appsuite-middleware>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry.open-xchange.com/appsuite-core-internal/charts/3rdparty | collabora-online | 1.1.58 |
| oci://registry.open-xchange.com/appsuite-core-internal/charts/3rdparty | gotenberg | 1.18.0 |
| oci://registry.open-xchange.com/appsuite-core-internal/charts | ox-common | 1.0.49 |

## Additional informations

### 4.0.0

- This version introduces new `configuration.redis` and `configuration.sessiond` section which **adds support for** Redis. Please refer to the documentation in `values.yaml`.
- Changed the default service type from `NodePort` to `ClusterIP` for `http-api`, `sync` and `admin` service.
- Removed *all* ingress configuration settings.
- Removed `services.documentconverterHost`, `services.imageconverterHost` and `services.spellcheckHost`.
Not necessary anymore but it's possible to override them e.g. via `.Values.global.dc.serviceName`
- Renamed environment variables
  - `OX_IMAGECONVERTER_URL` &rarr; `IC_SERVER_URL`
  - `OX_SPELLCHECK_URL` &rarr; `SPELLCHECK_SERVER_URL`
  - `OX_DOCUMENTCONVERTER_URL` &rarr; `DC_SERVER_URL`
- Partially or fully override `ox-common.names.fullname` via `nameOverride` or `fullnameOverride`.

### 5.10.1

- This version introduces new `configuration.redis.cache` section which **adds support for** a separate cache for volatile data. Please refer to the documentation in `values.yaml`.

### 6.0.1

- Hazelcast is now required for OX Documents only.
- Disabled packages `open-xchange-documents-backend` and `open-xchange-hazelcast` per default.
- Introduced a new role `documents` that enables packages `open-xchange-documents-backend` and `open-xchange-hazelcast` and adds necessary `HZ_*` env variables to containers. The role has been added to the `defaultScaling`.
- Removed `packages.minimalWhitelist` as it was not used anymore
- Removed role `hazelcast-data-holding` and `hazelcast-lite-member`

### 6.4.0

- Whether to use TLS to connect to the Redis endpoint can now be configured using `redis.tls.enabled` and `redis.cache.tls.enabled`.

### 6.19.5

- Added support for `PodDisruptionBudget` (PDB) via the new `pdb` configuration section.
- This version adds a new `middleware.open-xchange.com/type` label to pods. Upgrading to this version will trigger a rolling restart of all pods due to the label change.

## Upgrading

### To 6.0.1

If you are using custom node definitions (`scaling.nodes`) in your Helm values, please make sure to remove roles `hazelcast-data-holding` and `hazelcast-lite-member`.
Beside of that, a new role called `documents` has been introduced. The role needs to be added to every node definition that contains the `http-api` role and should run OX Documents.
Furthermore, it ensures that a Hazelcast headless service is still deployed for OX Documents.

Please consider the following `scaling.nodes` definition:

```
core-mw:
  scaling:
    nodes:
      groupware:
        replicas: 2
        roles:
          - admin
          - http-api
          - hazelcast-data-holding
      sync:
        replicas: 1
        roles:
          - sync
          - businessmobility
          - hazelcast-lite-member
```

A migrated version could look like this:

```
core-mw:
  scaling:
    nodes:
      groupware:
        replicas: 2
        roles:
          - admin
          - http-api
          - documents
      sync:
        replicas: 1
        roles:
          - sync
          - businessmobility
```

#### Warning

Nodes that do not have the role `documents` will not be deployed as a `StatefulSet` anymore. Instead they will be deployed as a `Deployment`.
Upgrading a `StatefulSet` to a `Deployment` is not easily possible without some preparation.
Simply upgrading via Helm would remove all pods of the `StatefulSet` before starting the first pod of the new `Deployment`.
This would result in a short downtime for endusers.

##### Example

Take a look at the following migrated example:

```
core-mw:
  scaling:
    nodes:
      groupware-without-docs:
        replicas: 2
        roles:
          - admin
          - http-api
      sync:
        replicas: 1
        roles:
          - sync
          - businessmobility
```

Nodes `groupware-without-docs` will not run OX Documents and roles `hazelcast-data-holding` and `hazelcast-lite-member` have been removed, too.
Prior `6.0.1`, those nodes were deployed as a `StatefulSet`. After the upgrade, they will be deployed as `Deployment`.
If downtime is not feasible, you need to do the following before the upgrade:

1. Remove the `StatefulSet` without removing the pods with:

```
kubectl delete statefulset appsuite-core-mw-groupware-without-docs --cascade=orphan
```

2. Upgrade via Helm

If you're low on resources, you should scale replicas to `0` in your `values.yaml`.
Otherwise, you will end up with the two pods from the `StatefulSet` and another two pods for the `Deployment`:

```
core-mw:
  scaling:
    nodes:
      groupware-without-docs:
        replicas: 0
        [...]
```

You can now upgrade the deployment via Helm:

```
helm upgrade [...]
```

After the upgrade, you can manually delete the `StatefulSet` pods and scale up the `Deployment`:

```
kubectl delete pod appsuite-core-mw-groupware-without-docs-1
kubectl scale deployment appsuite-core-mw-groupware-without-docs --replicas=1
kubectl delete pod appsuite-core-mw-groupware-without-docs-0
kubectl scale deployment appsuite-core-mw-groupware-without-docs --replicas=2
```

This process needs to be followed for all node definitions that previously had the `hazelcast-data-holding` role without having the `documents` role after the migration.

Don't forget to scale up the replicas in your `values.yaml` again.

## Configuration

The following table lists the configurable parameters of the `App Suite Middleware Core` chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment |
| asConfig.default.host | string | `"all"` |  |
| basicAuthLogin | string | `""` | The user name used for HTTP basic auth. |
| basicAuthPassword | string | `""` | The password used for HTTP basic auth. |
| checksums | object | `{"commonEnv":true,"config":true,"existingSecrets":true}` | Configures the checksum annotation used to trigger rolling updates. |
| checksums.commonEnv | bool | `true` | Detect changes in the shared App Suite secret. It does not detect changes in the Secret defined by `existingEnvSecret`. Please use `checksum.existingSecrets` for this. |
| checksums.config | bool | `true` | Detect config changes in ConfigMaps and Secrets that are created by this chart. |
| checksums.existingSecrets | bool | `true` | Detect changes in Secrets defined by `existing*` values (e.g. `existingPropertiesSecret` or `existingContextSetsSecret`). |
| collabora-online.enabled | bool | `false` | Whether `Collabora` should be enabled or not. |
| collabora-online.image.repository | string | `"registry.open-xchange.com/appsuite-core-internal/3rdparty/collabora-online"` |  |
| collabora-online.image.tag | string | `"25.04.9.2.1"` |  |
| configuration | object | `{"businessmobility":{"logging":{"debug":{"enabled":false,"logPath":""}}},"languages":[],"logging":{"debug":true,"file":{"maxFileSize":"2MB","maxIndex":99,"minIndex":0,"name":"/var/log/open-xchange/open-xchange.log.0","pattern":"/var/log/open-xchange/open-xchange.log.%i"},"json":{"prettyPrint":false},"logger":[{"level":"WARN","name":"org.apache.cxf"},{"level":"WARN","name":"com.openexchange.soap.cxf.logger"}],"logstash":{"host":"localhost","port":31337},"queueSize":2048,"root":{"file":false,"json":true,"level":"INFO","logstash":false},"syslog":{"facility":"USER","host":"localhost","port":514}}}` | Configuration |
| configuration.businessmobility.logging.debug.enabled | bool | `false` | Whether debug log is enabled or not |
| configuration.businessmobility.logging.debug.logPath | string | `""` | The path of the log file @default /var/log/open-xchange |
| configuration.languages | list | `[]` | List of languages which should be enabled. The default set of languages is `de_DE`, `en_US`, `es_ES`, `fr_FR` and `it_IT`.<br/> Example for enabling a couple of languages: `[ nl_NL, fi_FI, pl_PL ]` or for all available languages `[ all ]` |
| configuration.logging.debug | bool | `true` | Enables logback's debug mode |
| configuration.logging.json.prettyPrint | bool | `false` | Whether `PrettyPrint` is enabled |
| configuration.logging.logger | list | `[{"level":"WARN","name":"org.apache.cxf"},{"level":"WARN","name":"com.openexchange.soap.cxf.logger"}]` | List of named logger |
| configuration.logging.logstash | object | `{"host":"localhost","port":31337}` | Logstash configuration |
| configuration.logging.queueSize | int | `2048` | The number of logging events to retain for delivery |
| configuration.logging.root.file | bool | `false` | Whether `File` logging is enabled |
| configuration.logging.root.json | bool | `true` | Whether `JSON` logging is enabled |
| configuration.logging.root.level | string | `"INFO"` | Sets the log level of the root logger |
| configuration.logging.root.logstash | bool | `false` | Whether logging to `logstash` is enabled |
| configuration.logging.syslog | object | `{"facility":"USER","host":"localhost","port":514}` | Syslog configuration |
| containerPorts | list | `[{"containerPort":8009,"name":"http"}]` | Container ports |
| contextSets | object | `{}` | Context sets |
| createCommonEnv | bool | `true` | Whether to create a shared secret containing common properties as environment variables (e.g. SESSIOND_ENCRYPTION_KEY) |
| credstoragePasscrypt | string | `""` | Key to encrypt/decrypt the password held in credential storage. |
| defaultRegistry | string | `"registry.open-xchange.com"` | The default registry |
| defaultScaling.nodes.default.roles[0] | string | `"http-api"` |  |
| defaultScaling.nodes.default.roles[1] | string | `"sync"` |  |
| defaultScaling.nodes.default.roles[2] | string | `"admin"` |  |
| defaultScaling.nodes.default.roles[3] | string | `"businessmobility"` |  |
| defaultScaling.nodes.default.roles[4] | string | `"request-analyzer"` |  |
| defaultScaling.nodes.default.roles[5] | string | `"documents"` |  |
| documentConverterClient.cache.remoteCache | object | `{}` |  |
| enableDBConnectionCheck | bool | `true` | Whether to wait for configdb. |
| enableInitialization | bool | `false` | Whether initial bootstraping is enabled or not. |
| etcBinaries | list | `[]` | etc files |
| etcFiles | object | `{}` | etc files |
| existingASConfigSecret | string | `""` | Name of an existing secret with as-config.yaml |
| existingContextSetsSecret | string | `""` | Name of an existing secret with context sets |
| existingETCBinariesSecret | string | `""` | Name of an existing secret with binary files |
| existingETCFilesSecret | string | `""` | Name of an existing secret with files |
| existingEnvSecret | string | `""` | Name of an existing secret with environment variable that will be added to the container. Those env variable take precedence over the common and secret env vars, but not over extraEnv. |
| existingMetaSecret | string | `""` | Name of an existing secret with meta settings |
| existingPropertiesSecret | string | `""` | Name of an existing secret with properties |
| existingUISettingsSecret | string | `""` | Name of an existing secret with ui settings |
| existingYAMLFilesSecret | string | `""` | Name of an existing secret with yaml files |
| extraContainers | list | `[]` | List of extra sidecar containers |
| extraEnv | list | `[]` | List of extra environment variables |
| extraMounts | list | `[]` | List of extra mounts |
| extraPodSpec | object | `{}` | Extra PodSpec definitions |
| extraStatefulSetProperties | object | `{}` | List of extra StatefulSet properties |
| extraVolumes | list | `[]` | List of extra volumes |
| extras.monitoring.enabled | bool | `false` | Whether monitoring resources should be created, e.g. a `ConfigMap` containing the Grafana dashboards. |
| features | object | `{"definitions":{"admin":["open-xchange-admin","open-xchange-admin-contextrestore","open-xchange-admin-soap","open-xchange-admin-soap-usercopy","open-xchange-admin-user-copy"],"documents":["open-xchange-documents-backend","open-xchange-hazelcast"],"guard":["open-xchange-guard","open-xchange-guard-backend-mailfilter","open-xchange-guard-backend-plugin","open-xchange-guard-file-storage","open-xchange-guard-s3-storage"],"guard-admin":["open-xchange-guard-admin"],"omf-source":["open-xchange-omf-source","open-xchange-omf-source-dualprovisioning","open-xchange-omf-source-dualprovisioning-cloudplugins","open-xchange-omf-source-guard","open-xchange-omf-source-mailfilter"],"plugins":["open-xchange-plugins-antiphishing","open-xchange-plugins-antiphishing-vadesecure","open-xchange-plugins-blackwhitelist","open-xchange-plugins-blackwhitelist-sieve","open-xchange-plugins-contact-storage-group","open-xchange-plugins-contact-storage-provider","open-xchange-plugins-contact-whitelist-sync","open-xchange-plugins-mx-checker","open-xchange-plugins-onboarding-maillogin","open-xchange-plugins-trustedidentity","open-xchange-plugins-unsubscribe","open-xchange-plugins-unsubscribe-vadesecure"],"reseller":["open-xchange-admin-reseller","open-xchange-admin-soap-reseller"],"usm-eas":["open-xchange-usm","open-xchange-eas"],"weakforced":["open-xchange-weakforced"]},"status":{"documents":"disabled","omf-source":"disabled","plugins":"disabled","reseller":"disabled","usm-eas":"disabled","weakforced":"disabled"}}` | Feature definition |
| features.definitions.admin | list | see `values.yaml` | Admin definitions |
| features.definitions.documents | list | see `values.yaml` | Documents definitions |
| features.definitions.guard | list | see `values.yaml` | Guard definitions |
| features.definitions.omf-source | list | see `values.yaml` | OX2OX Migration Framework Source definitions |
| features.definitions.plugins | list | see `values.yaml` | Plugins definitions |
| features.definitions.reseller | list | see `values.yaml` | Reseller definitions |
| features.definitions.usm-eas | list | see `values.yaml` | USM EAS sync definitions |
| features.status | object | see `values.yaml` | Choose whether to enable or disable features. |
| fullnameOverride | string | `""` | Fully override of the `ox-common.names.fullname` template |
| global.extras.monitoring.enabled | bool | `false` |  |
| global.imageRegistry | string | `""` | Sets the image registry globally |
| global.mysql.existingSecret | string | `""` |  |
| gotenberg.chromium.disableJavaScript | bool | `true` |  |
| gotenberg.enabled | bool | `false` | Whether `Gotenberg` should be enabled or not. |
| gotenberg.extraEnv[0].name | string | `"XDG_DATA_HOME"` |  |
| gotenberg.extraEnv[0].value | string | `"/tmp/.data"` |  |
| gotenberg.extraEnv[1].name | string | `"XDG_CONFIG_HOME"` |  |
| gotenberg.extraEnv[1].value | string | `"/tmp/.config"` |  |
| gotenberg.extraEnv[2].name | string | `"XDG_CACHE_HOME"` |  |
| gotenberg.extraEnv[2].value | string | `"/tmp/.cache"` |  |
| gotenberg.image.repository | string | `"registry.open-xchange.com/appsuite-core-internal/3rdparty/gotenberg"` |  |
| gotenberg.image.tag | string | `"8.27.0"` |  |
| gotenberg.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| gotenberg.volumeMounts[0].mountPath | string | `"/tmp"` |  |
| gotenberg.volumeMounts[0].name | string | `"tmp-volume"` |  |
| gotenberg.volumes[0].emptyDir.medium | string | `"Memory"` |  |
| gotenberg.volumes[0].emptyDir.sizeLimit | string | `"256Mi"` |  |
| gotenberg.volumes[0].name | string | `"tmp-volume"` |  |
| hooks.beforeApply | object | `{}` |  |
| hooks.beforeAppsuiteStart | object | `{}` |  |
| hooks.start | object | `{}` |  |
| hzGroupName | string | `""` | The [Hazelcast](https://hazelcast.com/) group name. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"appsuite-core/middleware"` | Image repository |
| image.tag | string | `""` | Image tag |
| imagePullSecrets | list | `[]` | Reference to one or more secrets to be used when pulling images |
| initContainer | object | `{}` |  |
| istio.compression.enabled | bool | `false` | Whether to enable HTTP compression (gzip, deflate, etc.). |
| istio.injection.enabled | bool | `false` | Whether to enable sidecar injection or not. |
| istio.virtualServices.destinationPort | int | `80` | The virtual service destination port |
| javaOpts.debug.gcLogs.enabled | bool | `false` | Enables Java Garbage Collector logging |
| javaOpts.debug.heapdump.custom | object | `{}` | The definition of a custom volume excluding its name which shall be used instead of a hostpath volume. |
| javaOpts.debug.heapdump.enabled | bool | `false` | Enables Java Heap Dump creation in OOM situations |
| javaOpts.debug.heapdump.hostPath.dir | string | `"/mnt/appsuite-heap-dumps"` | hostPath directory on the k8s worker nodes, which needs to be created manually by the k8s admin. The directory will be mounted inside the core-mw container as '/heapdump'. |
| javaOpts.memory.maxHeapSize | string | `"2048M"` | Sets -XX:MaxHeapSize. Ignored if maxRAMPercentage is set. |
| javaOpts.memory.maxRAMPercentage | string | `""` | Sets -XX:MaxRAMPercentage instead of maxHeapSize. Takes precedence over maxHeapSize when set. |
| javaOpts.network | string | `""` |  |
| javaOpts.other | string | `""` |  |
| javaOpts.server | string | `""` |  |
| jolokiaLogin | string | `""` | User used for authentication with HTTP Basic Authentication. |
| jolokiaPassword | string | `""` | Password used for authentification with HTTP Basic Authentication. |
| masterAdmin | string | `""` | The name of the master admin. |
| masterPassword | string | `""` | The password of the master admin. |
| meta | object | `{}` | Meta |
| mysql.auth.password | string | `""` | The database password. *`(read/write connection)`* |
| mysql.auth.readPassword | string | `""` | The database password. *`(read connection)`* |
| mysql.auth.readUser | string | `""` | The database user name. *`(read connection)`* |
| mysql.auth.rootPassword | string | `""` | The MySQL `root` password. |
| mysql.auth.user | string | `""` | The database user name. *`(read/write connection)`* |
| mysql.auth.writePassword | string | `""` | The database password. *`(write connection)`* |
| mysql.auth.writeUser | string | `""` | The database user name. *`(write connection)`* |
| mysql.database | string | `""` | The database/schema name. *`(read/write connection)`* |
| mysql.existingSecret | string | `""` | Name of an existing secret. |
| mysql.host | string | `""` | The database host. *`(read/write connection)`* |
| mysql.port | string | `""` | The database port. *`(read/write connection)`* |
| mysql.readDatabase | string | `""` | The database/schema name. *`(read connection)`* |
| mysql.readHost | string | `""` | The database host. *`(read connection)`* |
| mysql.readPort | string | `""` | The database port. *`(read connection)`* |
| mysql.writeDatabase | string | `""` | The database/schema name. *`(write connection)`* |
| mysql.writeHost | string | `""` | The database host. *`(write connection)`* |
| mysql.writePort | string | `""` | The database port. *`(write connection)`* |
| nameOverride | string | `""` | Partially override of the `ox-common.names.fullname` template<br/> *NOTE: Preserves the release name.* |
| nodeSelector | object | `{}` | Tolerations for pod assignment |
| packages | object | `{"status":{"open-xchange-admin-autocontextid":"disabled","open-xchange-authentication-imap":"disabled","open-xchange-authentication-ldap":"disabled","open-xchange-authentication-masterpassword":"disabled","open-xchange-authentication-oauth":"disabled","open-xchange-cassandra":"disabled","open-xchange-dataretention-csv":"disabled","open-xchange-drive-client-windows":"disabled","open-xchange-eas-provisioning":"disabled","open-xchange-eas-provisioning-mail":"disabled","open-xchange-eas-provisioning-sms":"disabled","open-xchange-hostname-config-cascade":"disabled","open-xchange-hostname-ldap":"disabled","open-xchange-multifactor":"disabled","open-xchange-parallels":"disabled","open-xchange-passwordchange-script":"disabled","open-xchange-saml-core":"disabled","open-xchange-sms-sipgate":"disabled","open-xchange-sms-twilio":"disabled","open-xchange-spamhandler-parallels":"disabled","open-xchange-sso":"disabled"},"whitelist":[]}` | Packages By default, all packages will be enabled. If a package is defined within a feature and that `feature` is disabled, the package will not be started UNLESS it is explicitly reactivated in this section. All disabled packages will be written into the environment variable OX_BLACKLISTED_PACKAGES. |
| packages.status | object | see `values.yaml` | Choose whether to enable or disable packages. |
| packages.whitelist | list | `[]` | Whitelist The whitelist stands in contrast to the blacklist approach. Packages listed here are added to the OX_WHITELISTED_PACKAGES variable. This variable takes precedence over OX_BLACKLISTED_PACKAGES, causing the blacklist to be ignored. |
| pdb | object | `{"create":false,"maxUnavailable":"","minAvailable":""}` | Pod Disruption Budget configuration |
| pdb.create | bool | `false` | Whether a PodDisruptionBudget should be created |
| pdb.maxUnavailable | string | `""` | Maximum number or percentage of pods that can be unavailable. Mutually exclusive with minAvailable. Examples: 1, "25%" |
| pdb.minAvailable | string | `""` | Minimum number or percentage of pods that must be available. Mutually exclusive with maxUnavailable. Examples: 1, "50%" |
| podAnnotations | object | `{"logging.open-xchange.com/format":"appsuite-json"}` | Annotations to add to the pod |
| podSecurityContext | object | `{}` | The pod security context |
| priorityClassName | string | `""` | The priority class for pods |
| probe.liveness.enabled | bool | `true` | Enable the liveness probe |
| probe.liveness.failureThreshold | int | `15` | The liveness probe failure threshold |
| probe.liveness.httpGet | object | `{"path":"/live","port":8016,"scheme":"HTTP"}` | Specifies the HTTP request to perform |
| probe.liveness.httpGet.path | string | `"/live"` | Path to access on the HTTP server |
| probe.liveness.httpGet.port | int | `8016` | Name or number of the port to access on the container. Number must be in the range 1 to 65535. |
| probe.liveness.httpGet.scheme | string | `"HTTP"` | Scheme to use for connecting to the host (HTTP or HTTPS). Defaults to "HTTP". |
| probe.liveness.periodSeconds | int | `10` | The liveness probe period (in seconds) |
| probe.readiness.enabled | bool | `true` | Enable the readiness probe |
| probe.readiness.failureThreshold | int | `2` | The readiness probe failure threshold |
| probe.readiness.httpGet | object | `{"path":"/ready","port":8009,"scheme":"HTTP"}` | Specifies the HTTP request to perform |
| probe.readiness.httpGet.path | string | `"/ready"` | Path to access on the HTTP server |
| probe.readiness.httpGet.port | int | `8009` | Name or number of the port to access on the container. Number must be in the range 1 to 65535. |
| probe.readiness.httpGet.scheme | string | `"HTTP"` | Scheme to use for connecting to the host (HTTP or HTTPS). Defaults to "HTTP". |
| probe.readiness.initialDelaySeconds | int | `30` | The readiness probe initial delay (in seconds) |
| probe.readiness.periodSeconds | int | `5` | The readiness probe period (in seconds) |
| probe.readiness.timeoutSeconds | int | `5` | The readiness probe timeout (in seconds) |
| probe.startup.enabled | bool | `true` | Enable the startup probe |
| probe.startup.failureThreshold | int | `30` | The startup probe failure threshold |
| probe.startup.httpGet | object | `{"path":"/health","port":8009,"scheme":"HTTP"}` | Specifies the HTTP request to perform |
| probe.startup.httpGet.path | string | `"/health"` | Path to access on the HTTP server |
| probe.startup.httpGet.port | int | `8009` | Name or number of the port to access on the container. Number must be in the range 1 to 65535. |
| probe.startup.httpGet.scheme | string | `"HTTP"` | Scheme to use for connecting to the host (HTTP or HTTPS). Defaults to "HTTP". |
| probe.startup.initialDelaySeconds | int | `30` | The startup probe initial delay (in seconds) |
| probe.startup.periodSeconds | int | `10` | The startup probe period (in seconds) |
| probeHeaders | list | `[]` |  |
| properties | object | see `values.yaml` | Properties |
| propertiesFiles | object | `{}` | Properties files |
| rbac.create | bool | `true` | Whether Role-Based Access Control (RBAC) resources should be created |
| rbac.rules | list | `[]` | Custom RBAC rules |
| redis.affinity | object | `{}` | Affinity for pod assignment |
| redis.auth.password | string | `""` | The `Redis` password. |
| redis.auth.username | string | `""` | The `Redis` username. |
| redis.cache | object | `{"auth":{"password":"","username":""},"enabled":false,"hosts":[],"mode":"","sentinelMasterId":"","tls":{"enabled":false}}` | Configuration for a separate cache for volatile data. |
| redis.cache.auth.password | string | `""` | The `Redis` password. |
| redis.cache.auth.username | string | `""` | The `Redis` username. |
| redis.cache.enabled | bool | `false` | Whether a separate cache for volatile data is enabled or not, which is highly recommended in production. |
| redis.cache.hosts | list | `[]` | List of `Redis` hosts: <br/> Example for `redis`: [ <redis_host>:<redis_port> ] <br/> Example for `redis+sentinel`: [ <sentinel1_host>:<sentinel1_port>,<sentinel2_host>:<sentinel2_port>,<sentinel3_host>:<sentinel3_port> ] <br/> > Note: If `hosts` is empty or null, then an internal `redis`-standalone instance will be deployed. |
| redis.cache.mode | string | `""` | Redis operation mode (`standalone`, `cluster`, `sentinel`). |
| redis.cache.sentinelMasterId | string | `""` | Name of the `sentinel` masterSet, if operation mode is set to `sentinel`. |
| redis.cache.tls | object | `{"enabled":false}` | Redis TLS configuration. |
| redis.cache.tls.enabled | bool | `false` | Whether to use TLS to connect to Redis end-point or not. |
| redis.existingSecret | string | `""` | Name of an existing secret with Redis properties. |
| redis.extraEnvVars | list | `[]` | List of extra environment variables |
| redis.hosts | list | `[]` | List of `Redis` hosts: <br/> Example for `redis`: [ <redis_host>:<redis_port> ] <br/> Example for `redis+sentinel`: [ <sentinel1_host>:<sentinel1_port>,<sentinel2_host>:<sentinel2_port>,<sentinel3_host>:<sentinel3_port> ] <br/> > Note: If `hosts` is empty or null, then an internal `redis`-standalone instance will be deployed. |
| redis.image.repository | string | `"redis"` | Redis image repository |
| redis.image.tag | string | `"7-alpine"` | Redis image tag |
| redis.mode | string | `""` | Redis operation mode (`standalone`, `cluster`, `sentinel`) |
| redis.nodeSelector | object | `{}` | Node labels for pod assignment |
| redis.sentinelMasterId | string | `""` | Name of the `sentinel` masterSet, if operation mode is set to `sentinel`. |
| redis.tls | object | `{"enabled":false}` | Redis TLS configuration. |
| redis.tls.enabled | bool | `false` | Whether to use TLS to connect to Redis end-point or not. |
| redis.tolerations | list | `[]` | Tolerations for pod assignment |
| remoteDebug.enabled | bool | `false` | Whether Java Remote Debugging is enabled. |
| remoteDebug.nodePort | string | `nil` | The node port (default range: 30000-32767) |
| remoteDebug.port | int | `8102` | The Java Remote Debug port. |
| replicas | int | `1` | Number of nodes |
| resources | object | `{"limits":{"memory":"4096Mi"},"requests":{"cpu":"1000m","memory":"4096Mi"}}` | CPU/Memory resource requests/limits |
| restricted.drive.enabled | bool | `true` | If enabled tries to mount drive restricted configuration |
| restricted.mobileApiFacade.enabled | bool | `true` | If enabled tries to mount mobile api facade configuration |
| roles.admin.services[0].ports[0].name | string | `"http"` |  |
| roles.admin.services[0].ports[0].port | int | `80` |  |
| roles.admin.services[0].ports[0].protocol | string | `"TCP"` |  |
| roles.admin.services[0].ports[0].targetPort | string | `"http"` |  |
| roles.admin.services[0].type | string | `"ClusterIP"` |  |
| roles.businessmobility.services[0].ports[0].name | string | `"http"` |  |
| roles.businessmobility.services[0].ports[0].port | int | `80` |  |
| roles.businessmobility.services[0].ports[0].protocol | string | `"TCP"` |  |
| roles.businessmobility.services[0].ports[0].targetPort | string | `"http"` |  |
| roles.businessmobility.services[0].type | string | `"ClusterIP"` |  |
| roles.businessmobility.values.features.status.usm-eas | string | `"enabled"` |  |
| roles.businessmobility.values.properties."com.openexchange.usm.ox.url" | string | `"http://localhost:8009/appsuite/api/"` |  |
| roles.documents.controller | string | `"StatefulSet"` |  |
| roles.documents.services[0].headless | bool | `true` |  |
| roles.documents.services[0].name | string | `"hazelcast-headless"` |  |
| roles.documents.services[0].ports[0].name | string | `"tcp-hazelcast"` |  |
| roles.documents.services[0].ports[0].port | int | `5701` |  |
| roles.documents.statefulSetServiceName | string | `"hazelcast-headless"` |  |
| roles.documents.values.features.status.documents | string | `"enabled"` |  |
| roles.http-api.services[0].ports[0].name | string | `"http"` |  |
| roles.http-api.services[0].ports[0].port | int | `80` |  |
| roles.http-api.services[0].ports[0].protocol | string | `"TCP"` |  |
| roles.http-api.services[0].ports[0].targetPort | string | `"http"` |  |
| roles.http-api.services[0].type | string | `"ClusterIP"` |  |
| roles.request-analyzer.services[0].ports[0].name | string | `"http"` |  |
| roles.request-analyzer.services[0].ports[0].port | int | `80` |  |
| roles.request-analyzer.services[0].ports[0].protocol | string | `"TCP"` |  |
| roles.request-analyzer.services[0].ports[0].targetPort | string | `"http"` |  |
| roles.request-analyzer.services[0].type | string | `"ClusterIP"` |  |
| roles.sync.services[0].ports[0].name | string | `"http"` |  |
| roles.sync.services[0].ports[0].port | int | `80` |  |
| roles.sync.services[0].ports[0].protocol | string | `"TCP"` |  |
| roles.sync.services[0].ports[0].targetPort | string | `"http"` |  |
| roles.sync.services[0].type | string | `"ClusterIP"` |  |
| secretContextSets | object | `{}` | Secret Context sets |
| secretETCBinaries | list | `[]` | Secret etc files |
| secretETCFiles | object | `{}` | Secret etc files |
| secretProperties | object | `{}` | Secret properties |
| secretPropertiesFiles | object | `{}` | Secret properties files |
| secretUISettings | object | `{}` | Secret UI settings |
| secretUISettingsFiles | object | `{}` | Secret UI settings files |
| secretYAMLFiles | object | `{}` | Secret YAML files |
| securityContext | object | `{"allowPrivilegeEscalation":false}` | The security context |
| serverName | string | `"server"` | The server name. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| terminationGracePeriodSeconds | int | `60` | Duration in seconds the pod waits to terminate gracefully. |
| tolerations | list | `[]` | Tolerations for pod assignment |
| uiSettings | object | `{}` | UI settings |
| uiSettingsFiles | object | `{}` | UI settings files |
| update.enabled | bool | `false` | Whether an update task job for the specified database schemata is created or not |
| update.job | object | `{"ttlSecondsAfterFinished":86400}` | Job object settings |
| update.job.ttlSecondsAfterFinished | int | `86400` | The number of seconds after which a job is deleted automatically |
| update.schemata | string | `""` | Database schemata to update. If empty, all schemata will be updated. |
| update.types | list | `[]` | Filter for which types the update tasks are triggered. Every type with an unique bundle set will create a container in the update job. All containers (except one) are configured as init containers to ensure they run sequentially. |
| update.values | object | `{}` | Override type sepcific update values |
| useLegacyBashScripts | bool | `true` | Whether to use the old bash style init scripts. This is necessary if you want to use bash style hooks instead of go binaries. |
| yamlFiles | object | `{}` | YAML files |