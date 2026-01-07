# Installation Guide

This guide provides unified installation instructions for setting up a KubeAid-managed Kubernetes cluster across different hosting providers.

## Overview

KubeAid provides a streamlined installation process using the `kubeaid-cli` tool. The general workflow is consistent across all providers:

1. Install the KubeAid CLI  
2. Generate provider-specific configuration files  
3. Edit configuration files with your requirements  
4. Bootstrap the cluster  
5. Access and verify the cluster  

All KubeAid clusters include the following core components:

- **Cilium CNI** - running in kube-proxyless mode  
- **ArgoCD** - for GitOps-based deployments  
- **Sealed Secrets** - for secure secret management  
- **KubePrometheus** - for monitoring and alerting  
- **ClusterAPI** - for cluster lifecycle management (providers with API access, e.g., AWS, Azure, Hetzner)  
- **KubeOne** - for cluster initialization (SSH-only access platforms without API host management)  

## Installing KubeAid CLI

The KubeAid CLI is a unified tool for managing cluster setup across all providers. Install it on your local machine:

```bash
KUBEAID_CLI_VERSION=$(curl -s "https://api.github.com/repos/Obmondo/kubeaid-cli/releases/latest" | jq -r .tag_name)
OS=$([ "$(uname -s)" = "Linux" ] && echo "linux" || echo "darwin")
CPU_ARCHITECTURE=$([ "$(uname -m)" = "x86_64" ] && echo "amd64" || echo "arm64")

wget "https://github.com/Obmondo/kubeaid-cli/releases/download/${KUBEAID_CLI_VERSION}/kubeaid-cli-${KUBEAID_CLI_VERSION}-${OS}-${CPU_ARCHITECTURE}"
sudo mv kubeaid-cli-${KUBEAID_CLI_VERSION}-${OS}-${CPU_ARCHITECTURE} /usr/local/bin/kubeaid-cli
sudo chmod +x /usr/local/bin/kubeaid-cli
```

## Step 1: Generate configuration files

Each provider requires two configuration files: `general.yaml` and `secrets.yaml`. Generate these using the `kubeaid-cli config generate` command with your provider type. See [Step 1 - Details](#step-1---provider-specific-details) below for provider-specific commands and requirements.

The generated configuration templates will be saved in the `outputs/configs` directory.

> **Important:** Keep your `secrets.yaml` safe in your password store (e.g., [pass](https://www.passwordstore.org/)) for easy recovery. The `general.yaml` will be version-controlled in your `kubeaid-config` Git repository.

## Step 2: Edit configuration files

Review and modify the generated `general.yaml` and `secrets.yaml` files according to your specific requirements. These files contain:

- **`general.yaml`**: cluster specifications, node configurations, networking settings  
- **`secrets.yaml`**: sensitive credentials for cloud providers and Git repositories  

For detailed configuration options and examples for each provider, see the [Configuration Reference](../hosting/cloud-providers.md) documentation.  

## Step 3: Bootstrap the cluster

Run the bootstrap command to create your cluster:

```bash
kubeaid-cli cluster bootstrap
```

The bootstrap process will:

- Stream logs to your terminal (also saved in `outputs/.log`)  
- Create the necessary infrastructure  
- Initialize the Kubernetes cluster  
- Deploy ArgoCD and other core components  
- Save the kubeconfig to `outputs/kubeconfigs/clusters/main.yaml`  

## Step 4: Access the cluster

Once bootstrapped, access your cluster using `kubectl`:

```bash
export KUBECONFIG=./outputs/kubeconfigs/main.yaml
kubectl cluster-info
```

Explore your cluster by accessing the ArgoCD and Grafana dashboards.

## Step 1 - Provider-specific Details

### AWS

- **Generate configuration**

  ```bash
  kubeaid-cli config generate aws
  ```

- **Key features**
  - Kube2IAM for dynamic IAM credentials to pods  
  - Autoscalable node-groups with scale to/from 0 support  
  - Labels and taints propagation  
  - Disaster recovery using Velero  

- **Cleanup**

  ```bash
  kubeaid-cli cluster delete main
  kubeaid-cli cluster delete management
  ```

### Azure

- **Generate configuration**

  ```bash
  kubeaid-cli config generate azure
  ```

- **Key features**
  - Azure Workload Identity integration  
  - Autoscalable node-groups with scale to/from 0 support  
  - CrossPlane for infrastructure management  
  - Disaster recovery using Velero  

- **Cluster upgrades**

  Azure supports seamless Kubernetes version upgrades:

  ```bash
  kubeaid-cli cluster upgrade --new-k8s-version v1.32.0
  ```

  You can also specify a new OS image offer using the `--new-image-offer` flag.

- **Cleanup**

  ```bash
  kubeaid-cli cluster delete main
  kubeaid-cli cluster delete management
  ```

### Bare Metal (SSH-only)

- **Generate configuration**

  ```bash
  kubeaid-cli config generate bare-metal
  ```

- **Key features**
  - Uses [Kubermatic KubeOne](https://github.com/kubermatic/kubeone) for cluster initialization (SSH-only access—no API host management)  
  - Node-groups with labels and taints propagation  
  - No autoscaling (manual scaling only)  
  - Suitable for on-premise or self-managed servers where you control the machine lifecycle  

- **Cleanup**

  ```bash
  kubeaid-cli cluster delete main
  kubeaid-cli cluster delete management
  ```

### Hetzner HCloud

- **Generate configuration**

  ```bash
  kubeaid-cli config generate hetzner hcloud
  ```

- **Key features**
  - Autoscalable node-groups with scale to/from 0 support  
  - Cost-effective cloud infrastructure  
  - Full ClusterAPI integration  

- **Cleanup**

  ```bash
  kubeaid-cli cluster delete main
  kubeaid-cli cluster delete management
  ```

### Hetzner Bare Metal

- **Generate configuration**

  ```bash
  kubeaid-cli config generate hetzner bare-metal
  ```

- **Key features**
  - High-performance dedicated servers  
  - Custom disk layout configuration  
  - Software RAID (SWRAID) support  
  - Node-groups with labels and taints propagation  

- **Disk layout**

  Hetzner Bare Metal servers use level 1 SWRAID across specified disks, with a 25GB Logical Volume Group (`vg0`) containing a 10GB root volume for the OS. Further disk layout can be customized using the `diskLayoutSetupCommands` option.

- **Recommended disk allocation**
  - HDDs/SSDs: allocate to Ceph for distributed storage  
  - NVMes: allocate to ZPool (mirror mode) for Containerd, logs, and OpenEBS ZFS LocalPV  

- **Cleanup**

  ```bash
  kubeaid-cli cluster delete main
  kubeaid-cli cluster delete management
  ```

### Hetzner Hybrid

- **Generate configuration**

  ```bash
  kubeaid-cli config generate hetzner hybrid
  ```

- **Key features**
  - Control plane in HCloud  
  - Worker nodes in HCloud or Bare Metal (or both)  
  - Combines cloud flexibility with bare metal performance  
  - HCloud node-groups support autoscaling  

- **Cleanup**

  ```bash
  kubeaid-cli cluster delete main
  kubeaid-cli cluster delete management
  ```

### Local K3D (testing only)

- **Generate configuration**

  ```bash
  kubeaid-cli config generate local
  ```

- **Key features**
  - Quick local testing environment  
  - Runs on Docker using K3D  
  - Note: no cluster upgrades or disaster recovery support  

- **Cleanup**

  ```bash
  kubeaid-cli cluster delete management
  ```

## Post-installation

### Accessing services

After installation, you can access:

- **ArgoCD** - for GitOps application management  
- **Grafana** - for monitoring dashboards  
- **Prometheus** - for metrics and alerting  

### Secret management

KubeAid uses Sealed Secrets for secure secret management. Secrets are encrypted locally and committed to your `kubeaid-config` repository under  
`k8s/<cluster-name>/sealed-secrets/<namespace>/<name-of-secret>.json`.

### Updates and maintenance

To receive feature and security updates, you can either:

- Grant write access to your repos to the GitHub user `obmondo-pushupdate-user` for automatic updates  
- Manually pull updates using:

  ```bash
  git pull origin master
  ```

### Troubleshooting

- **Logs location**: all bootstrap logs are saved in `outputs/.log`  
- **Kubeconfig location**: `outputs/kubeconfigs/clusters/main.yaml`  
- **Config files**: `outputs/configs/general.yaml` and `outputs/configs/secrets.yaml`  

### Notes

- All clusters follow GitOps principles with ArgoCD  
- Changes should be made through Git, not directly in the cluster  
- Never modify the `master`/`main` branch of your KubeAid repository mirror  
- All customizations go in your `kubeaid-config` repository  
