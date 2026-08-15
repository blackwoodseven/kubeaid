# Getting Started with KubeAid

This guide walks you through the complete process of setting up and managing a KubeAid-managed Kubernetes cluster. The
workflow is **provider-agnostic** and the steps are the same whether you're deploying on AWS, Azure, Hetzner, bare
metal, or locally.

## Overview

KubeAid is a **Kubernetes management suite** that helps you set up and operate Kubernetes clusters following **GitOps
principles**.

```mermaid
---
title: KubeAid features
---
flowchart LR
    subgraph Obs["Observability"]
        KP["KubePrometheus<br/>+ Alerting"]
    end
    subgraph Git["GitOps"]
        AG["ArgoCD +<br/>Sealed Secrets"]
    end
    subgraph Scale["Auto-scaling"]
        AS["Scale to/from<br/>Zero"]
    end
    subgraph Mgmt["Cluster Management"]
        CM["ClusterAPI +<br/>KubeOne"]
    end
    
    Obs ~~~ Git ~~~ Scale ~~~ Mgmt
```

All KubeAid clusters include:

- **Cilium CNI** - running in kube-proxyless mode  
- **ArgoCD** - for GitOps-based deployments  
- **Sealed Secrets** - for secure secret management  
- **KubePrometheus** - for monitoring and alerting  
- **ClusterAPI** - for cluster lifecycle management (providers with API access)  
- **KubeOne** - for cluster initialization (SSH-only access platforms)

## Installation Steps

Follow these steps in order to set up your cluster:

| Step | Document | Description |
| ------ | ---------- | ------------- |
| 1 | [Prerequisites](./prerequisites.md) | Verify required tools, repositories, and provider credentials |
| 2 | [Pre-Configuration](./pre-configuration.md) | Generate and configure `general.yaml` and `secrets.yaml` |
| 3 | [Installation](./installation.md) | Bootstrap the cluster using `kubeaid-cli` |
| 4 | [Post-Configuration](./post-configuration.md) | Access dashboards, verify setup, and configure services |

## Cluster Operations

After installation, use these guides for ongoing cluster management:

| Operation | Document | Description |
| ----------- | ---------- | ------------- |
| Basic Operations | [Basic Operations](./basic-operations.md) | Basic operations including deletion and clean-up |

## Supported Providers

KubeAid supports the following hosting environments:

| Provider | Type | Autoscaling | Notes |
| ---------- | ------ | ------------- | ------- |
| **AWS** | Cloud (API-managed) | ✅ Scale to/from 0 | Uses ClusterAPI |
| **AWS EKS** | Cloud (managed control plane) | ✅ Scale to/from 0 | CAPA; upgrade via GitOps bump, recover not yet |
| **Azure** | Cloud (API-managed) | ✅ Scale to/from 0 | Uses ClusterAPI |
| **Azure AKS** | Cloud (managed control plane) | ✅ AKS agent pools | CAPZ; upgrade via GitOps bump, recover not yet |
| **Hetzner HCloud** | Cloud (API-managed) | ✅ Scale to/from 0 | Uses ClusterAPI |
| **Hetzner Bare Metal** | Dedicated servers | ❌ Manual | Uses ClusterAPI |
| **Hetzner Hybrid** | Cloud + Bare Metal | ✅ HCloud only | Uses ClusterAPI |
| **Bare Metal (SSH-only)** | On-premise | ❌ Manual | Uses KubeOne |
| **Local K3D** | Development | ❌ | For testing only |

> **Note:** ClusterAPI is used for providers with API access for host management. KubeOne is used for SSH-only access
  platforms where there is no API for host management.

## Quick Start

For experienced users, here's the minimal workflow. The
[KubeAid CLI quick start](https://github.com/Obmondo/kubeaid-cli#quick-start) is the authoritative, always-current
version of this sequence.

```bash
# 1. Install the CLI
curl -fsSL https://raw.githubusercontent.com/Obmondo/kubeaid-cli/main/scripts/install.sh | sh

# 2. Generate general.yaml and secrets.yaml via the interactive prompt
kubeaid-cli config generate --configs-directory ./outputs/configs/<cluster>/

# 3. Review the generated files, then bootstrap
kubeaid-cli cluster bootstrap --configs-directory ./outputs/configs/<cluster>/

# 4. Access cluster
export KUBECONFIG=./outputs/kubeconfigs/clusters/main.yaml
kubectl cluster-info
```
