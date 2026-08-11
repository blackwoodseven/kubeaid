# Pre-Configuration

This step covers generating and configuring the `general.yaml` and `secrets.yaml` files required for cluster setup.
The configuration process is **the same across all providers** - only some field values differ.

## Overview

KubeAid uses two configuration files:

| File | Contains | Storage |
| ------ | ---------- | --------- |
| `general.yaml` | Cluster specs, node configs, networking settings | Version-controlled in `kubeaid-config` repo |
| `secrets.yaml` | Credentials for cloud providers and Git | **Store in password manager** (e.g., [pass](https://www.passwordstore.org/)) |

> **Tip:** If you want to be able to recreate this cluster setup after it has been deleted,
> you must save `general.yaml` to your kubeaid-config repository.
> **Important:** Always save your `secrets.yaml` in a secure password store for easy recovery. Never commit secrets to Git.

## Step 1: Generate Configuration Files

Run the config generate command with your provider type:

```bash
kubeaid-cli config generate <provider>
```

Replace `<provider>` with one of:

| Provider | Command |
| ---------- | ------- |
| AWS | `kubeaid-cli config generate aws` |
| Azure | `kubeaid-cli config generate azure` |
| Hetzner HCloud | `kubeaid-cli config generate hetzner hcloud` |
| Hetzner Bare Metal | `kubeaid-cli config generate hetzner bare-metal` |
| Hetzner Hybrid | `kubeaid-cli config generate hetzner hybrid` |
| Bare Metal (SSH-only) | `kubeaid-cli config generate bare-metal` |
| Local K3D | `kubeaid-cli config generate local` |

The generated templates are saved in `outputs/configs/`.

### Generated Directory Structure

After running the config generate command, your working directory will look like:

```bash
your-working-directory/
├── outputs/
│   ├── configs/
│   │   ├── general.yaml      # Cluster configuration (edit this)
│   │   └── secrets.yaml      # Credentials (edit this, store in password manager)
│   ├── kubeconfigs/          # Generated after bootstrap
│   │   └── main.yaml         # Kubeconfig for your cluster
│   └── .log                  # Bootstrap logs
└── ...
```

## Step 2: Configure general.yaml

The `general.yaml` file defines your cluster's infrastructure. Most fields are **common across all providers**.

### Common Configuration (All Providers)

```yaml
# Repository URLs
forkURLs:
  kubeaid: https://github.com/<your-org>/KubeAid
  kubeaidConfig: https://github.com/<your-org>/kubeaid-config

# Cluster specification
cluster:
  name: my-cluster              # Unique cluster name
  k8sVersion: v1.31.0           # Kubernetes version
  kubeaidVersion: 18.0.0        # KubeAid version

# Git configuration
git:
  useSSHAgentAuth: false
  useSSHPrivateKeyAuth: false

# ArgoCD configuration
argocd:
  useSSHPrivateKeyAuth: false
  kubeaidURL: https://github.com/<your-org>/KubeAid
  kubeaidConfigURL: https://github.com/<your-org>/kubeaid-config
```

### Provider-Specific Configuration

The `cloud` section differs by provider. Below are the key fields for each:

#### AWS

```yaml
cloud:
  aws:
    region: eu-central-1         # Frankfurt; change to your preferred region
    sshKeyName: kubeaid-demo    # Name of your AWS SSH keypair
    controlPlane:
      instanceType: t3.medium
      replicas: 3
    nodePools:
      - name: workers
        instanceType: t3.large
        minSize: 1
        maxSize: 10
```

#### AWS EKS (managed control plane)

Set `eks: true` to get an AWS managed (EKS) control plane instead of the
self-managed EC2 one. AWS runs the control plane multi-AZ, CAPA resolves the
EKS optimized AL2023 worker AMIs itself, and workers stay keyless — so
`controlPlane`, `sshKeyName` and per-node-group AMIs must be left unset.
Requires Kubernetes >= v1.33.

```yaml
cloud:
  aws:
    region: eu-central-1
    eks: true
    bastionEnabled: true
    nodeGroups:
      - name: default
        minSize: 3
        maxSize: 6
        cpu: 4
        memory: 8
        instanceType: c6i.xlarge
        rootVolumeSize: 35
```

> **Note:** `cluster upgrade` doesn't apply to EKS clusters — bump
> `global.kubernetes.version` in `argocd-apps/values-capi-cluster.yaml` in your
> kubeaid-config repo and let ArgoCD sync; CAPA then upgrades the control plane
> and rolls the node-groups.

#### Azure

```yaml
cloud:
  azure:
    subscriptionId: <subscription-id>
    resourceGroup: my-cluster-rg
    location: westeurope          # Amsterdam; change to your preferred region
    controlPlane:
      vmSize: Standard_D2s_v3
      replicas: 3
    nodePools:
      - name: workers
        vmSize: Standard_D4s_v3
        minSize: 1
        maxSize: 10
```

#### Azure AKS (managed control plane)

Set `aks: true` to get an Azure managed (AKS) control plane instead of the
self-managed VM one. Azure owns the control plane, the node images and the
agent-pool autoscaling, and CAPZ authenticates with your AAD service principal
directly — so `controlPlane`, `sshPublicKey`, `canonicalUbuntuImage`,
`storageAccount`, `workloadIdentity` and `aadApplication` must all be left
unset. Node-groups become AKS agent pools: the first one is the required
`System` pool, and names must be 1-12 lowercase alphanumeric characters
starting with a letter.

```yaml
cloud:
  azure:
    tenantID: <tenant-id>
    subscriptionID: <subscription-id>
    location: westeurope
    aks: true
    nodeGroups:
      - name: default
        minSize: 3
        maxSize: 6
        cpu: 4
        memory: 8
        vmSize: Standard_F4s_v2
        diskSizeGB: 128
```

> **Note:** Register the `KubeProxyConfigurationPreview` feature on your
> subscription before bootstrapping (see [Prerequisites](./prerequisites.md)) —
> KubeAid disables AKS's kube-proxy and runs Cilium with kube-proxy
> replacement. Like EKS, `cluster upgrade` doesn't apply: bump
> `global.kubernetes.version` in `argocd-apps/values-capi-cluster.yaml` and let
> ArgoCD sync.

#### Hetzner HCloud

```yaml
cloud:
  hetzner:
    hcloud:
      region: nbg1
      sshKeyName: kubeaid-demo
      controlPlane:
        serverType: cpx31
        replicas: 3
      nodePools:
        - name: workers
          serverType: cpx41
          minSize: 1
          maxSize: 10
```

> **Note:** HCloud storage only allows a maximum of 16 buckets per physical node. Plan your PV usage accordingly
> to avoid running out of PVs before node resources are exhausted.

#### Hetzner Bare Metal

```yaml
cloud:
  hetzner:
    bareMetal:
      wipeDisks: false          # Set true to wipe existing RAID
      controlPlane:
        serverIds: [123456, 123457, 123458]  # Must be unique within the cluster
      nodePools:
        - name: workers
          serverIds: [234567, 234568]        # Must be unique within the cluster
          labels:
            node-type: worker
          taints: []
```

> **Note:** Server IDs must be unique within a cluster. Each server can only belong to one node pool
> (either control plane or a worker pool).

#### Hetzner Hybrid

```yaml
cloud:
  hetzner:
    hcloud:
      # Control plane in HCloud
      controlPlane:
        serverType: cpx31
        replicas: 3
    bareMetal:
      # Workers in Bare Metal
      nodePools:
        - name: bare-metal-workers
          serverIds: [234567, 234568]
```

#### Bare Metal (SSH-only)

```yaml
cloud:
  bareMetal:
    controlPlane:
      hosts:
        - address: 10.0.0.1
          user: root
        - address: 10.0.0.2
          user: root
        - address: 10.0.0.3
          user: root
    nodePools:
      - name: workers
        hosts:
          - address: 10.0.0.10
            user: root
          - address: 10.0.0.11
            user: root
        labels:
          node-type: worker
        taints: []
```

> **Note:** The IP addresses shown above (e.g., `10.0.0.1`) are examples. You can use any valid private IP range
> (RFC 1918) such as:
>
> - `10.0.0.0/8` (10.0.0.0 – 10.255.255.255)
> - `172.16.0.0/12` (172.16.0.0 – 172.31.255.255)
> - `192.168.0.0/16` (192.168.0.0 – 192.168.255.255)
>
> These addresses are for **internal cluster communication** and should not be publicly routable.
> The control plane addresses are used for the Kubernetes API server and etcd cluster,
> while worker addresses are for node-to-node and pod networking.

#### Local K3D

```yaml
cloud:
  local: {}
```

## Step 3: Configure secrets.yaml

The `secrets.yaml` file contains sensitive credentials. **Do not commit this file to Git.**

### Common Secrets (All Providers)

```yaml
# Git credentials for ArgoCD
git:
  username: <git-username>
  password: <personal-access-token>

# Docker registry (optional)
dockerRegistry:
  username: ""
  password: ""

# ArgoCD admin password
argocd:
  admin:
    password: <strong-password>
```

### Provider-Specific Secrets

#### AWS Secrets

```yaml
aws:
  accessKeyId: <aws-access-key>
  secretAccessKey: <aws-secret-key>
```

#### Azure Secrets

```yaml
azure:
  clientId: <service-principal-client-id>
  clientSecret: <service-principal-secret>
  tenantId: <azure-tenant-id>
```

#### Hetzner

```yaml
hetzner:
  hcloudToken: <hcloud-api-token>
  robotUser: <robot-username>           # For bare metal only
  robotPassword: <robot-password>       # For bare metal only
```

#### Bare Metal (SSH-only) Secrets

```yaml
ssh:
  privateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
```

## Step 4: Validate Configuration

Before proceeding, verify your configuration:

1. **Check file locations:**

   ```bash
   ls -la outputs/configs/
   # Should show: general.yaml, secrets.yaml
   # Expected owner: your current user (or root if running as root)
   # Expected file mode: -rw------- (600) for secrets.yaml to protect credentials
   #                     -rw-r--r-- (644) is acceptable for general.yaml
   ```

2. **Validate YAML syntax:**

   ```bash
   yq eval '.' outputs/configs/general.yaml > /dev/null && echo "general.yaml is valid"
   yq eval '.' outputs/configs/secrets.yaml > /dev/null && echo "secrets.yaml is valid"
   ```

3. **Store secrets securely:**

   ```bash
   # Example using pass
   pass insert kubeaid/my-cluster/secrets.yaml < outputs/configs/secrets.yaml
   ```
