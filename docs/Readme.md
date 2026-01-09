# KubeAid Documentation

## Overview

* Configure your Kubernetes cluster on AWS, Azure, Hetzner (Bare Metal, HCloud or Hybrid), Bare Metal or Local K3D, with the KubeAid CLI.

* The cluster are private and terragrunt can also setup a wireguard instance,
  which will be the only gateway to access your kubernetes (You can skip the wireguard part as well)

## Prerequisite

1. Need this package to be installed on your local machine

   ```text
   kubectl
   jq
   terragrunt
   terraform
   bcrypt
   wireguard
   yq (https://github.com/mikefarah/yq)
   ```

2. Git repository

   a. clone the kubeaid git repo from obmondo
   b. Create a fresh git repo (for better naming, we usually call it kubeaid-config)

## Installation

For complete installation instructions, see the **[Getting Started Guide](./getting-started/README.md)** which includes:

- Prerequisites
- Pre-configuration
- Installation (supports AWS, Azure, Hetzner, Bare Metal, and Local K3D)
- Post-configuration
- Basic Operations (including cleanup)

## Hosting Reference

For hosting-specific details and considerations, see:

- [Cloud Providers](./hosting/cloud-providers.md) (AWS, Azure, Hetzner HCloud)
- [Bare Metal](./hosting/bare-metal.md)
- [Single Host K8s](./hosting/single-host-k8s.md)
- [Hybrid Setup](./hosting/hybrid-setup.md)

## Operations

- [Backup & Restore](./operations/backup-restore.md)
- [Node Reboot](./operations/node-reboot.md)
- [AWS Private Link Setup](./operations/aws-private-link-setup.md)
- [Monitoring](./operations/monitoring/)
  - [Pod Autoscaling](./operations/monitoring/pod-autoscaling.md)
  - [Prometheus Namespaces](./operations/monitoring/prometheus-namespaces.md)

## Development

- [Update ArgoCD Apps](./update_kubeaid_argocd_apps.md)

## Support

For general questions, bug reports, and feature requests, please use our **[GitHub Issues](https://github.com/Obmondo/kubeaid/issues)**.

Besides the community support, the primary developers of this project offer support via services on [Obmondo.com](https://obmondo.com) - where you can opt to have us observe your world and react to your alerts, and/or help you with developing new features or other tasks on clusters using this project.

## Feature and Security Updates

We regularly update our Helm charts from upstream repositories and ensure that you don't miss out on
important security updates. To simplify updates, you can grant write access to your `kubeaid` and `kubeaid-config` repo
created in step 2 above - to the github user `obmondo-pushupdate-user`.

This will enable us to automatically push the latest updates to your repo and allow us to adjust your
cluster and app configuration, which we need to be able to do - if you're a subscriber with us.

Alternatively, you can pull the updates from our repo after cloning it on your systems using:

```sh
git pull origin master
```
