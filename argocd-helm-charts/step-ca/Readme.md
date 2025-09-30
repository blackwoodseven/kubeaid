# Step CA Helm Chart

This chart deploys the Smallstep toolchain (step-certificates, step-issuer, autocert and trust-manager) to provide an internal ACME-compatible Certificate Authority for KubeAid clusters.

## Prerequisites

- cert-manager installed in the cluster
- Access to the `kubeaid-config` repository to supply cluster-specific values

## Deployment Steps

1. **Copy values**: Start from `argocd-helm-charts/step-ca/examples/values.yaml` and place the file in your `kubeaid-config` repository (for example `k8s/{cluster}/argocd-apps/values-step-ca.yaml`).
2. **Deploy via ArgoCD/Helm**: Point the Step CA Application at this chart with the copied values file.
3. **Fetch credentials once pods are ready**:
   ```sh
   kubectl get -n step-ca -o jsonpath="{.data['root_ca\.crt']}" configmaps/step-ca-step-certificates-certs | base64 | tr -d '\n'
   kubectl get -n step-ca -o jsonpath="{.data['ca\.json']}" configmaps/step-ca-step-certificates-config | jq -r .authority.provisioners[0].key.kid
   ```
4. **Update cert-manager values**: Add the `kid` and `root_ca` outputs to the `stepClusterIssuer` section of your Step CA values file so they are available to other apps.

## Integrating with cert-manager

Each certificate issuer in KubeAid lives in its own Helm chart. When you want cert-manager to request certificates from Step CA, reference the Step CA chart outputs in the cert-manager values file and enable the ClusterIssuer template (`argocd-helm-charts/cert-manager/templates/clusterissuer.yaml`). A minimal snippet looks like:

```yaml
issuer:
  name: step-ca
  enabled: true
  stepCA:
    enabled: true
    caBundle: "<root_ca_output>"
```

> NOTE: The Step CA ClusterIssuer becomes available only after the step-certificates pod finishes bootstrapping.

## Consuming the Root CA

Expose the root CA inside workloads by:
- Mounting the exported secret
- Passing the PEM via environment variables
- Injecting the bundle via webhook (for example trust-manager)

Most runtimes (e.g. Go via `SSL_CERT_FILE`) will trust TLS connections signed by this internal CA once the file is mounted.

* Imp Notes:

- The provisioner password is generated automatically by the chart. The step-certificates pod waits for this secret before starting.
- Keep the generated `root_ca` and provisioner credentials secure and back them up according to your organization’s policy.
