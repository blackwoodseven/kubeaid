# Graylog docs

## Log monitoring in KubeAid

Graylog is a **log-only** monitoring option in KubeAid. It runs alongside
[`kube-prometheus`](../../docs/kubeaid/prometheus-configuration.md) (Prometheus, Alertmanager, Grafana), which
continues to handle metrics and metric-based alerts.

| | |
| - | - |
| **Scope** | Log ingestion, search, pipelines, and log-based alerting |
| **Log collection** | Fluent Bit, Fluentd, Beats, Syslog, GELF, and other Graylog inputs |
| **Prometheus integration** | None — Graylog does not pull metrics or alerts from Prometheus |
| **Storage** | OpenSearch (indexed logs) and MongoDB (Graylog metadata) |

See [Monitoring](../../docs/monitoring.md) for how Graylog compares to
OpenObserve and OpenSearch + Kibana.

The sections below cover installation, configuration, and operations.

---


```sh
# pwgen 20 1 | tr -d '\n' > graylog-password
# cat graylog-password | sha256sum | tr -d '\n' > graylog-sha2
# kubectl create secret generic graylog -n graylog  --dry-run=client --from-file=graylog-password-secret=./graylog-password --from-file=graylog-password-sha2=./graylog-sha2 -o json >graylog.json
# kubeseal --controller-name sealed-secrets --controller-namespace system < graylog.json > graylog-final.json
```

**TODO:** Add infomation about creating the graylog-es-svc secret

## Port forwarding to access the Graylog

**Note: this is handy when authentication via header is enabled.**

```sh
kubectl port-forward -n graylog svc/graylog 9091:9000
```

## set admin password (in standalone setup)

Helm chart takes care of converting the password into `sha256` hash. [configure](https://docs.graylog.org/en/4.0/pages/getting_started/configure.html)

```sh
echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
```

Push this new string out in graylog secret - key graylog-password-sha2

## Beats input

To create Beats input, go to the web interface:

* Go to the inputs page (Menu bar->System->Inputs)
* In the "Select input" drop down menu, select "Beats"
* Click "Launch new input"
* Enter the following in the form:
  * Title: Beats
  * Port: 5044
  * Enable the "Do not add Beats type as prefix" option, at the bottom
* Click "Save"

## Index and log retention configuration

* Go to the "Configure Index Set" page (Menu bar->System->Indices)
* Click the `edit` button, next to the "Default index set"
* In the "Index Rotation Configuration" section
  * Select rotation strategy: `Index Time`
  * Rotation period: `P1D`
* In the "Index Retention Configuration" section
  * Select retention strategy: `Delete Index`
  * Max number of indices: `180`

## trigger index cycle now (instead of at night)

```sh
curl -XPOST http://127.0.0.1:9000/api/system/deflector/cycle -H 'X-Requested-By: localhost'
```

login (user+password) can be found in secret called graylog - field `data.graylog-password-secret`

## Connecting MongoDB

Graylog needs to connect to MongoDB to store configs. This chart uses the MongoDB operator to
add a database by creating an object of `kind: MongoDBCommunity`.

The object also tells the operator to create a separate `graylog` database
and a `graylog-user` with `readWrite` permissions. It expects a secret `graylog-user-password`
containing the password which will be used by graylog client later.

The connection string for the graylog client is generated and kept in a secret
called `mongodb-replica-set-graylog-graylog-user`. The string is of the form :

```bash
mongodb://graylog-user:<password>@mongodb-replica-set-0.mongodb-replica-set-svc.graylog.svc.cluster.local:27017/graylog?replicaSet=mongodb-replica-set&ssl=false
```

This username and password combination allows the Graylog client to authenticate itself to the MongoDB instance.

**NOTE: Do not use `userAdminAnyDatabase` role of MongoDB as it does not have permissions to create index.**

Create the mongodb graylog-user password

```bash
kubectl create secret generic graylog-user-password -n default --dry-run=client --from-literal=password=lolpassword -o yaml
```

## 🔧 Critical Configuration: Prevent Deflector Race Conditions

By default, OpenSearch allows the automatic creation of indices. If the cluster experiences temporary instability during a Graylog index rotation, incoming log traffic can cause OpenSearch to mistakenly auto-create a physical `graylog_deflector` index before Graylog has a chance to create the routing alias. This creates a roadblock that completely breaks the log ingestion pipeline.

To prevent this race condition, you must explicitly forbid OpenSearch from auto-creating any index containing the word "deflector". 

**Apply the following persistent cluster setting:**

```bash
curl -X PUT "http://localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "action.auto_create_index": "-*deflector*,+*"
  }
}
'

## Opensearch (elasticsearch fork with open source license)

```bash
kubectl create secret generic graylog-es-svc -n graylog --from-literal=url='http://admin:admin@opensearch-cluster-master:9200' -o yaml
```

## Upgrade Instruction

Graylog and OpenSearch are both under active development. This means that new versions are released
frequently. This guide will help you upgrade your Graylog and OpenSearch installation to the
latest version.

* Check the graylog interoperability chart to see which version of Graylog is compatible with the
version of OpenSearch and mongodb you are upgrading to.
https://go2docs.graylog.org/5-0/planning_your_deployment/planning_your_upgrade_to_opensearch.htm

### 1. Upgrading MongoDB

* Take a backup of the mongodb by running the backup job manually.

    ```bash
    kubectl create job --from=cronjob/mongodb-backup manual-backup -n graylog
    ```

* In the graylog application Sync the mongodb-community crd changes first as the MongoDb v5.0
  is not compatible with graylog v4.3.9.
* Expect graylog to go down during the upgrade process.

### 2. Upgrading Graylog

* Sync the graylog application in the argocd.
* Wait for the graylog pods to be in running state.
* Check the logs
* Check the graylog UI for any errors.

### 3. Upgrading OpenSearch

* Take a snapshot

    ```bash
    kubectl create job --from=cronjob/opensearch-s3-snapshot-create manual-snapshot -n graylog
    ```

* Sync the opensearch application in the argocd.
* Wait for the opensearch pods to be in running state.
* opensearch cluster are not downgradable, so please restore it from snapshot (look at opensearch helm chart readme)

## Backup and Restore (source -> target migration runbook)

This section documents a tested procedure to migrate Graylog configuration data from a
source cluster to a target cluster.

### Naming convention used in this guide

* `source -> target`: generic migration direction.
* `<source-context>` / `<target-context>`: `kubectl` contexts for source and target clusters.
* Replace placeholders with your environment-specific names before running commands.

### Scope

* Backs up and restores the Graylog MongoDB config database.
* Does **not** restore OpenSearch indices (target OpenSearch stays empty by design).

### 1) Audit source versions

Capture and document exact runtime versions before migration:

* Graylog image tag
* MongoDB image tag
* OpenSearch image tag

Example:

```bash
kubectl --context <source-context> -n graylog get pods -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{range .spec.containers[*]}{.image}{" "}{end}{"\n"}{end}'
```

### 2) Create MongoDB dump on source

Use the generated Graylog Mongo connection string from secret
`mongodb-replica-set-graylog-graylog-user` and run `mongodump` inside the MongoDB pod.

```bash
CTX_SOURCE='<source-context>'
NS='graylog'
URI="$(kubectl --context "$CTX_SOURCE" -n "$NS" get secret mongodb-replica-set-graylog-graylog-user -o jsonpath='{.data.connectionString\.standard}' | base64 -d)"

kubectl --context "$CTX_SOURCE" -n "$NS" exec mongodb-replica-set-0 -c mongod -- \
  env HOME=/tmp sh -c "mongodump --uri='$URI' --db graylog --excludeCollection=index_failures --out /tmp/graylog-dump"
kubectl --context "$CTX_SOURCE" -n "$NS" exec mongodb-replica-set-0 -c mongod -- \
  tar czf /tmp/graylog-mongo-dump.tgz -C /tmp graylog-dump
kubectl --context "$CTX_SOURCE" -n "$NS" cp mongodb-replica-set-0:/tmp/graylog-mongo-dump.tgz ./graylog-mongo-dump.tgz
```

Note: `index_failures` may need to be excluded if pod memory is constrained.

### 3) Restore dump on target

Scale Graylog down before restore, restore DB, then scale Graylog back up.

```bash
CTX_TARGET='<target-context>'
NS='graylog'
URI="$(kubectl --context "$CTX_TARGET" -n "$NS" get secret mongodb-replica-set-graylog-graylog-user -o jsonpath='{.data.connectionString\.standard}' | base64 -d)"

kubectl --context "$CTX_TARGET" -n "$NS" scale statefulset graylog --replicas=0
kubectl --context "$CTX_TARGET" -n "$NS" cp ./graylog-mongo-dump.tgz mongodb-replica-set-0:/tmp/graylog-mongo-dump.tgz
kubectl --context "$CTX_TARGET" -n "$NS" exec mongodb-replica-set-0 -c mongod -- \
  sh -c "mkdir -p /tmp/restore && tar xzf /tmp/graylog-mongo-dump.tgz -C /tmp/restore"
kubectl --context "$CTX_TARGET" -n "$NS" exec mongodb-replica-set-0 -c mongod -- \
  env HOME=/tmp mongorestore --uri "$URI" --drop /tmp/restore/graylog-dump/graylog
kubectl --context "$CTX_TARGET" -n "$NS" scale statefulset graylog --replicas=2
```

### 4) Post-restore requirements

If Graylog fails with `Invalid password_secret! Failed to decrypt values from MongoDB`,
sync the target `graylog` secret values with the source cluster values for:

* `graylog-password-secret`
* `graylog-password-sha2`

These are crypto settings used by Graylog to decrypt DB content and must match restored data.

### 5) Login/password reset note

In this dataset, MongoDB user passwords are stored in legacy format:

`{bcrypt}<hash>{salt}<hash-prefix>`

If manual password reset is needed, preserve this format; storing plain `$2a$...` or
`{bcrypt}$2a$...` only can lead to login failures.

### 6) Validation checklist

After restore, verify:

* Graylog UI is accessible on target.
* Key config object counts match source for:
  * `streams`
  * `dashboards`
  * `event_definitions`
  * `pipeline_processor_rules`
  * `pipeline_processor_pipelines`
  * `inputs`
* OpenSearch has no historical data (fresh/empty target as intended).

General MongoDB operator backup/restore reference:
[../mongodb-operator/Readme.md#backup-and-restore](../mongodb-operator/Readme.md#backup-and-restore)

### Example migration outcome (source -> target)

Migration is complete and acceptance criteria are satisfied.

* Audited and documented source runtime versions:
  1. Graylog `6.3.1`
  2. MongoDB `5.0.14-ubi8`
  3. OpenSearch `2.19.2`
* Captured MongoDB backup from source (authenticated dump).
* Deployed fresh Graylog/MongoDB/OpenSearch stack on target with matching versions.
* Restored MongoDB dump to target successfully (no restore failures reported).
* Verified Graylog UI accessibility on target and successful admin-capable login.
* Verified restored configuration parity between source and target for key collections:
  1. `streams` `3/3`
  2. `dashboards` `1/1`
  3. `event_definitions` `1/1`
  4. `pipeline_processor_rules` `0/0`
  5. `pipeline_processor_pipelines` `0/0`
  6. `inputs` `1/1`
  7. `event_notifications` `missing/missing`
  8. `lookup_tables` `missing/missing`

Notes:

* `index_failures` was excluded from backup due to OOM on full dump attempt; this is an expected limitation in constrained environments.
* Password reset/login issue was resolved by using the dataset's expected legacy Graylog password storage format: `{bcrypt}...{salt}...`.
