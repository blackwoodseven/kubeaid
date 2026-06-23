# MongoDB Operator Migration Guide: MCO to MCK (ArgoCD)

This guide outlines the procedure for migrating from the legacy **MongoDB Community Operator (MCO)** to the new **MongoDB Kubernetes Operator (MCK)** when managed via **ArgoCD**.

This migration ensures that CustomResourceDefinitions (CRDs) and running database instances are preserved, preventing data loss or service disruption.

---

## 📋 Prerequisites

1. **Verify CRD Keep Annotations**:
   Ensure your existing `MongoDBCommunity` CRD has Helm's `keep` resource policy annotation. Without this, uninstalling the old chart will cause Kubernetes to delete the CRD and all associated databases and PVs.
   ```bash
   kubectl get crd mongodbcommunity.mongodbcommunity.mongodb.com -o yaml | grep 'helm.sh/resource-policy'
   ```
   *Expected Output:*
   ```yaml
   helm.sh/resource-policy: keep
   ```

2. **ArgoCD Sync Policy**:
   During the migration, you should temporarily disable automatic pruning (`Prune=false`) on the ArgoCD application managing the old operator to prevent accidental deletion of resources.

---

## 🚀 Migration Steps

### Step 1: Scale Down the Old Operator (Prevent Split-Brain)
Before introducing the new operator, scale down the old MCO deployment to 0 replicas to prevent both operators from trying to reconcile resources at the same time:
```bash
kubectl scale deployment mongodb-community-operator --replicas=0 -n <operator-namespace>
```

### Step 2: Remove the Old Operator Chart via Orphan Delete
To delete the old Helm release/ArgoCD resources without deleting the CRD or database resources, remove the old operator's resources using an **orphan delete**:
* In ArgoCD: Delete the old operator application and make sure to **disable/uncheck "Cascade"** (orphan the resources).
* Or via CLI:
  ```bash
  kubectl delete deployment mongodb-community-operator -n <operator-namespace> --cascade=orphan
  ```

### Step 3: Handle the Immutable Selector Error (Gotcha)
When syncing the new MCK chart (`mongodb-kubernetes`), ArgoCD will try to patch the existing operator deployment. If the deployment's label selector changed (e.g. from the community operator's selector to the new unified operator selector), ArgoCD will throw the following error:
```text
one or more objects failed to apply, reason: error when patching "/dev/shm/2542400350": Deployment.apps "mongodb-kubernetes-operator" is invalid: spec.selector: Invalid value: v1.LabelSelector{MatchLabels:v1.LabelSelectorRequirement(nil)}: field is immutable
```

#### Solution:
Since `spec.selector` is immutable, you must manually delete the active operator deployment so ArgoCD can recreate it from scratch:
```bash
kubectl delete deployment mongodb-kubernetes-operator -n <operator-namespace>
```

### Step 4: Sync the New MCK Chart
1. Point your ArgoCD application (or Helm values) to the new repository and chart `mongodb-kubernetes` (version `>= 1.8.1`).
2. Sync the new chart in ArgoCD. 
3. ArgoCD will now successfully deploy the new `mongodb-kubernetes-operator` deployment.

---

## ✅ Verification
1. Watch the new operator pod start up and begin reconciliation:
   ```bash
   kubectl logs -f deployment/mongodb-kubernetes-operator -n <operator-namespace>
   ```
2. The new operator will automatically assume ownership of the existing `MongoDBCommunity` CRs.
3. It will update the database RBAC and service accounts, triggering a **rolling restart** of your database pods. Verify all database pods return to a `2/2` or `3/3` healthy and running state:
   ```bash
   kubectl get pods -n <database-namespace> -w
   ```
