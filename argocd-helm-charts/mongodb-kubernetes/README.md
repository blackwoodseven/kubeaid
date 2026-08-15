# MongoDB Kubernetes Operator (MCK)

[MongoDB Controllers for Kubernetes (MCK)](https://github.com/mongodb/mongodb-kubernetes) is MongoDB's unified
operator: it reconciles MongoDB deployments (including the `MongoDBCommunity` replica-set CRs previously handled
by the separate MongoDB Community Operator, MCO) into standardized, repeatable StatefulSet deployments.

This is a KubeAid wrapper around the upstream
[mongodb-kubernetes chart](https://github.com/mongodb/helm-charts) (version 1.9.1), which installs the operator
and its CRDs.

## Why it's in KubeAid

Application charts in KubeAid do not run their own MongoDB — [`kubeaid-addons`](../kubeaid-addons) provisions a
`MongoDBCommunity` replica set plus a logical-backup CronJob per namespace (`global.mongodb.enabled`). This
operator is the controller that turns those CRs into running database pods. It replaces the retired
`mongodb-operator` (MCO) chart; see the migration section below.

## Key values / KubeAid-specific configuration

The wrapper's `values.yaml` is intentionally empty — upstream defaults are used as-is. Override upstream values
under the `mongodb-kubernetes:` key in your cluster's values file in kubeaid-config, e.g.:

```yaml
mongodb-kubernetes:
  operator:
    watchNamespace: "*"
```

See the vendored chart's [values.yaml](./charts/mongodb-kubernetes/values.yaml) for the full set.

## Operational notes

- The CRDs ship with the chart. `MongoDBCommunity` CRs from an MCO install keep working — the new operator
  assumes ownership of them (details below).
- Deleting the Argo CD app with cascade would delete CRDs and, with them, every database. Keep the
  `helm.sh/resource-policy: keep` annotation on the CRDs and prune carefully.

## Docs links

- Upstream operator: <https://github.com/mongodb/mongodb-kubernetes>
- Upstream chart: <https://github.com/mongodb/helm-charts>
- KubeAid MongoDB provisioning: [`kubeaid-addons`](../kubeaid-addons)

## Migration: MCO → MCK

This guide outlines the procedure for migrating from the legacy **MongoDB Community Operator (MCO)** to the new
**MongoDB Kubernetes Operator (MCK)** when managed via **ArgoCD**.

This migration ensures that CustomResourceDefinitions (CRDs) and running database instances are preserved,
preventing data loss or service disruption.

### Prerequisites

1. **Verify CRD Keep Annotations**:
   Ensure your existing `MongoDBCommunity` CRD has Helm's `keep` resource policy annotation. Without this,
   uninstalling the old chart will cause Kubernetes to delete the CRD and all associated databases and PVs.
   ```bash
   kubectl get crd mongodbcommunity.mongodbcommunity.mongodb.com -o yaml | grep 'helm.sh/resource-policy'
   ```
   *Expected Output:*
   ```yaml
   helm.sh/resource-policy: keep
   ```

2. **ArgoCD Sync Policy**:
   During the migration, you should temporarily disable automatic pruning (`Prune=false`) on the ArgoCD
   application managing the old operator to prevent accidental deletion of resources.

### Migration Steps

#### Step 1: Scale Down the Old Operator (Prevent Split-Brain)

Before introducing the new operator, scale down the old MCO deployment to 0 replicas to prevent both operators
from trying to reconcile resources at the same time:
```bash
kubectl scale deployment mongodb-community-operator --replicas=0 -n <operator-namespace>
```

#### Step 2: Remove the Old Operator Chart via Orphan Delete

To delete the old Helm release/ArgoCD resources without deleting the CRD or database resources, remove the old
operator's resources using an **orphan delete**:

* In ArgoCD: Delete the old operator application and make sure to **disable/uncheck "Cascade"** (orphan the
  resources).
* Or via CLI:
  ```bash
  kubectl delete deployment mongodb-community-operator -n <operator-namespace> --cascade=orphan
  ```

#### Step 3: Handle the Immutable Selector Error (Gotcha)

When syncing the new MCK chart (`mongodb-kubernetes`), ArgoCD will try to patch the existing operator deployment.
If the deployment's label selector changed (e.g. from the community operator's selector to the new unified
operator selector), ArgoCD will throw the following error:
```text
one or more objects failed to apply, reason: error when patching "/dev/shm/2542400350": Deployment.apps "mongodb-kubernetes-operator" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:v1.LabelSelectorRequirement(nil)}: field is immutable
```

Since `spec.selector` is immutable, you must manually delete the active operator deployment so ArgoCD can
recreate it from scratch:
```bash
kubectl delete deployment mongodb-kubernetes-operator -n <operator-namespace>
```

#### Step 4: Sync the New MCK Chart

1. Point your ArgoCD application (or Helm values) to the new repository and chart `mongodb-kubernetes`
   (version `>= 1.8.1`).
2. Sync the new chart in ArgoCD.
3. ArgoCD will now successfully deploy the new `mongodb-kubernetes-operator` deployment.

### Verification

1. Watch the new operator pod start up and begin reconciliation:
   ```bash
   kubectl logs -f deployment/mongodb-kubernetes-operator -n <operator-namespace>
   ```
2. The new operator will automatically assume ownership of the existing `MongoDBCommunity` CRs.
3. It will update the database RBAC and service accounts, triggering a **rolling restart** of your database pods.
   Verify all database pods return to a `2/2` or `3/3` healthy and running state:
   ```bash
   kubectl get pods -n <database-namespace> -w
   ```
