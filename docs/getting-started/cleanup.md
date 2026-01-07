# Take Down

This guide covers how to delete and clean up your KubeAid-managed Kubernetes cluster. The process is **the same for all providers**.

## Before You Begin

> **Warning:** Cluster deletion is **irreversible**. Ensure you have:
> - Backed up any important data
> - Exported any sealed secrets you want to preserve
> - Saved your `secrets.yaml` in your password store

## Delete the Cluster

### Step 1: Delete the Main Cluster

```bash
kubeaid-cli cluster delete main
```

This command will:
- Drain and remove all worker nodes
- Delete the control plane
- Remove cloud resources (for cloud providers)

### Step 2: Delete the Management Cluster

```bash
kubeaid-cli cluster delete management
```

This command removes the local management cluster used during bootstrapping.

### Complete Cleanup Command

For a single command cleanup:

```bash
kubeaid-cli cluster delete main && kubeaid-cli cluster delete management
```

## Provider-Specific Notes

### AWS

After deletion, verify all AWS resources are cleaned up:

```bash
# Check for lingering resources
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=owned"
aws elb describe-load-balancers
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=owned"
```

If resources remain, delete them manually through the AWS Console or CLI.

### Azure

Verify resource group cleanup:

```bash
az group list --query "[?contains(name, '<cluster-name>')]"
```

If the resource group still exists, delete it:

```bash
az group delete --name <cluster-name>-rg --yes --no-wait
```

### Hetzner

#### HCloud

Verify servers are deleted:

```bash
hcloud server list
```

Check for lingering volumes:

```bash
hcloud volume list
```

#### Bare Metal

For Hetzner Bare Metal, servers are not automatically wiped. You must manually:

1. Reset servers via the Hetzner Robot interface
2. Or reinstall the OS if you plan to reuse them

### Bare Metal (SSH-only)

For SSH-only bare metal servers, the physical machines remain. To clean up:

1. SSH into each node
2. Run cleanup commands:

```bash
# On each node
kubeadm reset -f
rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd
iptables -F && iptables -X
ipvsadm --clear
```

### Local K3D

Local K3D clusters are automatically cleaned up. Verify:

```bash
docker ps -a | grep k3d
k3d cluster list
```

## Clean Up Local Files

After cluster deletion, optionally clean up local files:

```bash
# Remove generated outputs (keep if you want to inspect logs)
rm -rf outputs/

# Keep your secrets.yaml backup in password store!
```

## Recreating a Cluster

To create a new cluster with the same configuration:

1. Ensure your `general.yaml` is saved (in your kubeaid-config repo)
2. Retrieve your `secrets.yaml` from your password store
3. Follow the [Pre-Configuration](./pre-configuration.md) and [Installation](./installation.md) guides
