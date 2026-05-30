# Helm Chart core-cacheservice
This Helm Chart deploys Cache service core in a kubernetes cluster.

## Introduction
This Chart includes the following components:

* Cache service application container to deploy in a kubernetes cluster.

## Requirements
Requires Kubernetes v1.19+

## Dependencies
This section will provide details about specific requirements in addition to this Helm Chart.
## Pushing to registry
From wihtin ${PROJECT_DIR}/helm/core-cacheservice directory:

```shell
helm repo add ox-documents-registry https://registry.open-xchange.com/chartrepo/documents
helm repo update
helm push . ox-documents-registry
```

## Test installation
Run a test against a cluster deployment:

```shell
helm repo add ox-documents-registry https://registry.open-xchange.com/chartrepo/documents
helm repo update
helm install --dry-run --debug --generate-name --version [VERSION] ox-documents-registry/core-cacheservice
```

## Installing the chart
Install the Chart with the release name 'alice':

```shell
helm repo add ox-documents-registry https://registry.open-xchange.com/chartrepo/documents
helm repo update
helm install alice --version [VERSION] ox-documents-registry/core-cacheservice [-f path/to/values_with_credentials.yaml]
```

## Configuration
| Parameter                                                      | Description                                                                                                                                                                                    | Default                     |
|----------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|
| `defaultRegistry`                                              | The image registry                                                                                                                                                                             | `registry.open-xchange.com` |
| `image.repository`                                             | The image repository                                                                                                                                                                           | `core-cacheservice`         |
| `image.tag`                                                    | The image tag                                                                                                                                                                                  | ``                          |
| `image.pullPolicy`                                             | The imagePullPolicy for the deployment                                                                                                                                                         | `IfNotPresent`              |
| `imagePullSecrets`                                             | List of references to secrets for image registries                                                                                                                                             | `[]`                        |
| `ingress.enabled`                                              | Make ImageConverter service reachable from outside of cluster                                                                                                                                  | `false`                     |
| `ingress.controller`                                           | The type of controller to use, possible values are `nginx` and `traefik`                                                                                                                       | `nginx`                     |
| `ingress.hosts`                                                | The list of hosts the service can be reached from. Set to empty to allow from everywhere.                                                                                                      | `[]`                        |
| `ingress.hosts.host`                                           | The host the service can be reached from                                                                                                                                                       | `chart-example.local`       |
| `existingPropertiesSecret`                                     | The name of an already existing secret within the deployment namespace, containing lean config values (e.g. user names and passwords for BasicAuth as well as database, S3 access etc.)        | ``                          |
| `basicAuthLogin`                                               | The user name for BasicAuth login, required for protected HTTP API calls                                                                                                                       | ``                          |
| `basicAuthPassword`                                            | The password for BasicAuth login, required for protected HTTP API calls                                                                                                                        | ``                          |
| `cacheService.cacheDefaults.maxEntries`                        | The maximum number of cache key entries. Use -1 for unlimited.                                                                                                                                 | `100000`                    |
| `cacheService.cacheDefaults.maxSizeMegaBytes`                  | The maximum size of all cache key entries combined. Use -1 for unlimited.                                                                                                                      | `-1`                        |
| `cacheService.cacheDefaults.maxLifetimeSeconds`                | The maximum age in seconds of a cache key entry before it gets removed. Use -1 for unlimited.                                                                                                  | `2592000`                   |
| `cacheService.cacheDefaults.cleanupPeriodSeconds`              | The period in seconds after which the next cache cleanup will be performed                                                                                                                     | `300`                       |
| `cacheService.mysql.host`                                      | The CacheService database connection host                                                                                                                                                      | ``                          |
| `cacheService.mysql.port`                                      | The CacheService database connection port                                                                                                                                                      | `3306`                      |
| `cacheService.mysql.database`                                  | The CacheService database connection schema                                                                                                                                                    | `cacheservicedb`            |
| `cacheService.mysql.auth.user`                                 | The CacheService database connection user                                                                                                                                                      | ``                          |
| `cacheService.mysql.auth.password`                             | The CacheService database connection password                                                                                                                                                  | ``                          |
| `cacheService.mysql.auth.rootPassword`                         | The CacheService database connection root password to create e.g. a new database                                                                                                               | ``                          |
| `cacheService.mysql.properties`                                | The optional CacheService database connection properties to pass to the database drivers.                                                                                                      | `[]`                        |
| `cacheService.mysql.connectionPool.connectTimeoutMilliseconds` | The timeout value in milliseconds to get a connection from the connection pool                                                                                                                 | `2000`                      |
| `cacheService.mysql.connectionPool.maxLifetimeMilliseconds`    | The maximum lifetime value in milliseconds for a connection from the connection pool                                                                                                           | `600000`                    |
| `cacheService.mysql.connectionPool.idleTimeoutMilliseconds`    | The timeout value in milliseconds to release an idle connection from the connection pool                                                                                                       | `300000`                    |
| `cacheService.mysql.connectionPool.maxPoolSize`                | The maximum value of connections to be held within the connection pool                                                                                                                         | `10`                        |
| `cacheService.mysql.connectionPool.minPoolIdleSize`            | The minimum value of idle connections to be held within the connection pool. This value is half of the maximumPoolSize by default.                                                             | ``                          |
| `cacheService.s3ObjectStores`                                  | The list of S3 object stores to use                                                                                                                                                            | `[]`                        |
| `cacheService.s3ObjectStores.id`                               | The numeric id of the current S3 based object store that shouldn't be changed once assigned                                                                                                    | ``                          |
| `cacheService.s3ObjectStores.endpoint`                         | The endpoint URL of the current S3 object store                                                                                                                                                | ``                          |
| `cacheService.s3ObjectStores.region`                           | The region of the current S3 object store                                                                                                                                                      | `eu-central-1`              |
| `cacheService.s3ObjectStores.bucketName`                       | The bucket name of the current S3 object store                                                                                                                                                 | `cacheservice`              |
| `cacheService.s3ObjectStores.accessKey`                        | The access key of the current S3 object store                                                                                                                                                  | ``                          |
| `cacheService.s3ObjectStores.secretKey`                        | The secret key of the current S3 object store                                                                                                                                                  | ``                          |
| `cacheService.s3ObjectStores.trace`                            | Enables/Disables trace logging output for the internally used S3 client library                                                                                                                | `false`                     |
| `cacheService.sproxydObjectStores`                             | The list of SproxyD object stores to use                                                                                                                                                       | `[]`                        |
| `cacheService.sproxydObjectStores.id`                          | The numeric id of the current SproxyD based object store that shouldn't be changed once assigned                                                                                               | ``                          |
| `cacheService.sproxydObjectStores.endpoint`                    | The endpoint URL of the current SproxyD based object store                                                                                                                                     | ``                          |
| `cacheService.sproxydObjectStores.path`                        | The path where to store objects in the current SproxyD based object store                                                                                                                      | `proxyd/cacheservice`       |
| `cacheService.jvmHeapSizeMB`                                   | The maximum JVM heap size of the image Java process to use in MegaBytes                                                                                                                        | `768`                       |
| `persistence.enabled`                                          | Specifies if cluster volumes are mounted by container. Using emptyDir Volumes when false.                                                                                                      | `false`                     |
| `logging.*`                                                    | Specifies logging configuration values.<br/>All file size related values are specified either in Bytes (no Postfix), KiloBytes (KB postfix), MegaBytes (MB postfix) or GigaBytes (GB postfix). | ``                          |
| `env`                                                          | Configuration properties passed to the service via environment variables                                                                                                                       | `[]`                        |

## Configuration of service properties via existing secret

In most cases, like with this service, the Helm stack chart provided values for a service are transformed into a ConfigMap properties file
created during the Helm stackchart update/install step for a deployment. These config values are then used by the service container/pod during startup.
Although this approach covers all relevant config properties for the service, it is often desirable for the admin to specify all or just some
of the service config properties via a kubernetes secret for e.g. security reasons.

To provide a way to use service config values from an existing secret within the current deployment namespace, the service Helm chart contains
a property to specify the name of an existing secret within the deployment namespace: `.Values.existingPropertiesSecret`.
Service properties (key/value pairs) set within this secret always have precedence over service properties contained within the Helm chart
created ConfigMap property values.

Documentation for the service-specific configuration values can be found at this [configuration values](https://documentation.open-xchange.com/components/cacheservice/8/config/properties.html)
location.

Since authorization data is most prone to security attacks, the following example will concentrate on these properties only, although all other
service properties can be set via a deployed secret this way as well:

- HTTP API BasicAuth properties (com.openexchange.cacheservice.basicAuth.user, com.openexchange.cacheservice.basicAuth.password)
- DB authorization properties (com.openexchange.cacheservice.database.user, com.openexchange.cacheservice.database.password, com.openexchange.cacheservice.database.rootPassword)
- S3 authorization properties (com.openexchange.cacheservice.objectstore.s3.1.accessKey, com.openexchange.cacheservice.objectstore.s3.1.secretKey)

### Example steps to provide a service config properties/values secret to be used by the deployed service
#### Step 1
First of all, a secret containing all required service config property keys and values needs to be created (current filename is ./myCacheServiceSecret.yaml)
Please note that all config values need to be set as Base64 encoded values.
All my* names and values need to be adjusted according to the admins' requirements.

```
apiVersion: v1
kind: Secret
metadata:
  name: my-cacheservice-secret
type: Opaque
data:
  com.openexchange.cacheservice.basicAuth.user: bXlCYXNpY0F1dGhVc2VyCg==  # Base64 encoded value of `myBasicAuthUser`
  com.openexchange.cacheservice.basicAuth.password: bXlCYXNpY0F1dGhQYXNzd29yZAo=  # Base64 encoded value of `myBasicAuthPassword`
  com.openexchange.cacheservice.database.user: bXlEQlVzZXIK  # Base64 encoded value of `myDBUser`
  com.openexchange.cacheservice.database.password: bXlEQlBhc3N3b3JkCg==  # Base64 encoded value of `myDBPassword`
  com.openexchange.cacheservice.database.rootPassword: bXlEQlJvb3RQYXNzd29yZAo=  # Base64 encoded value of `myDBRootPassword`
  com.openexchange.cacheservice.objectstore.s3.1.accessKey: bXlTM0FjY2Vzc0tleQo=  # Base64 encoded value of `myS3AccessKey`
  com.openexchange.cacheservice.objectstore.s3.1.secretKey: bXlTM1NlY3JldEtleQo=  # Base64 encoded value of `myS3SecretKey`
```
#### Step 2
After preparing all config values within the secret definition, the secret itself needs to be deployed or updated to the deployment namespace.
```
kubectl replace --force=true --namespace=myNamespace --filename=./myCacheServiceSecret.yaml
```
#### Step 3
After the property secret has been deployed to the cluster namespace the admin needs to adjust the service `.Values.existingPropertiesSecret`
stackchart value for the service.
```
core-cacheservice:
  existingPropertiesSecret: my-cacheservice-secret
```
#### Step 4
The stackchart with the set Helm chart service value `.Values.existingPropertiesSecret` name needs to be installed or updated via usual deployment mechanisms.
After the deployment has been finished, the service itself preferably uses the service key/value properties from the secret.
If a secret has already been deployed and secret values need changes, the secret itself needs to be redeployed to be effective. Afterward the
service itself needs to be restarted as well to acknowledge the new secret properties key/value pairs.
