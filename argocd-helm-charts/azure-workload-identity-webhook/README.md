# Azure Workload Identity Webhook

Wrapper chart for the upstream [`workload-identity-webhook`](https://azure.github.io/azure-workload-identity/charts)
chart (pinned to `1.6.0`, appVersion `v1.6.0`), the mutating admission webhook that projects an Azure AD federated
token into pods annotated for [Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/),
letting them authenticate to Azure APIs without stored credentials.

## Why it's in KubeAid

Rendered for **self-managed (CAPZ) Azure clusters** (`AzureSpecificNonSecretTemplateNames`), where it's part of
the self-managed workload-identity machinery alongside Crossplane, the storage-account OIDC provider, and
user-assigned managed identities (UAMIs). **AKS** clusters skip it — `AzureAKSSpecificNonSecretTemplateNames` is
empty because AKS provides workload identity natively via its own OIDC issuer.

## Key values / KubeAid-specific configuration

Upstream values live under the `workload-identity-webhook:` key.

- `azureTenantID` is set by `kubeaid-cli` from the cluster's Azure config (`.AzureConfig.TenantID`) — required so
  the webhook can validate/exchange tokens against the right AAD tenant.

## Docs links

- Upstream chart & docs: <https://azure.github.io/azure-workload-identity/docs/>
- Upstream project: <https://github.com/Azure/azure-workload-identity>
- [KubeAid: Helm umbrella pattern](../../docs/kubeaid/helm-umbrella-pattern.md)
