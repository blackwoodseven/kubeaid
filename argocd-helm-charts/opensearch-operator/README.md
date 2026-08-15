# OpenSearch Operator

Wrapper around the upstream [opensearch-operator](https://github.com/opensearch-project/opensearch-k8s-operator)
Helm chart (v3.0.2). No KubeAid-specific `values.yaml` or templates - this chart passes the upstream chart
through unmodified. Installs the operator and its CRDs (`OpenSearchCluster`, `OpenSearchISMPolicy`, and
others) that manage OpenSearch clusters declaratively.

## Why it's in KubeAid

Lets an OpenSearch cluster be managed as an `OpenSearchCluster` custom resource instead of a plain
StatefulSet. This is a distinct install path from the [`opensearch`](../opensearch) chart, which deploys the
standard upstream `opensearch` Helm chart directly and does not itself create an `OpenSearchCluster`
resource - as of this writing, no chart in this repo instantiates that CRD. `opensearch` is one of KubeAid's
three log-storage options (alongside Graylog and OpenObserve - see the comparison in
[Monitoring](../../docs/monitoring.md)), used either as Graylog's backend or as a standalone log store paired
with [`opensearch-dashboards`](../opensearch-dashboards).

## Key values / KubeAid-specific configuration

None - this chart has no local `values.yaml` or templates; it passes the upstream chart through unmodified.
Configure the operator entirely through the upstream chart's values under the `opensearch-operator` key -
manager resources, probes, security context, and so on. See the
[upstream README](https://github.com/opensearch-project/opensearch-k8s-operator/blob/main/charts/opensearch-operator/README.md)
for the full parameter list.

## Docs links

- [OpenSearch Kubernetes Operator user guide](https://github.com/opensearch-project/opensearch-k8s-operator/blob/main/docs/userguide/main.md)
- [Monitoring / log stack comparison](../../docs/monitoring.md)
- Related: [`opensearch`](../opensearch), [`opensearch-dashboards`](../opensearch-dashboards), [`graylog`](../graylog)
