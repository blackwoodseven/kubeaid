# Prerequisites  
  
This guide outlines the prerequisites for setting up a KubeAid-managed Kubernetes cluster across different hosting environments.  
  
## Common Dependencies  
  
Before setting up any KubeAid cluster, ensure you have the following tools and resources ready:  
  
### Required Software  
  
The following packages must be installed on your local machine:  
  
- `kubectl` - Kubernetes command-line tool  
- `jq` - JSON processor  
- `terragrunt` - Terraform wrapper  
- `terraform` - Infrastructure as Code tool  
- `bcrypt` - Password hashing utility  
- `wireguard` - VPN software (optional, for private cluster access)  
- `yq` - YAML processor (https://github.com/mikefarah/yq)
  
### Docker  
  
Have Docker running locally on your machine. Docker Desktop is recommended for both Linux and MacOS users.
  
### Git Repositories  
  
You need to set up two Git repositories:  
  
1. **KubeAid Repository**: Fork or mirror the [KubeAid repository](https://github.com/Obmondo/kubeaid) from Obmondo.   
     
   **Important**: Never make changes on the master/main branch of your mirror of the KubeAid repository, as this branch is used to deliver updates. All customizations should happen in your `kubeaid-config` repository.
  
2. **KubeAid Config Repository**: Fork the [KubeAid Config repository](https://github.com/Obmondo/kubeaid-config), which will contain your cluster-specific configurations.
  
### Git Provider Credentials  
  
Keep your Git provider credentials ready. These will be used by ArgoCD for GitOps operations.  
  
#### GitHub  
  
Create a [Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token) with permission to write to your KubeAid Config fork. This PAT will be used as the password.
  
**Best Practice**: Create a separate user called `obmondo-<service>-user` and use its Personal Access Token instead of your personal account token.
  
#### GitLab  
  
For GitLab, you can create a Project Access Token (available in self-hosted and enterprise GitLab) or create a separate user called `obmondo-<service>-user` and provide its Personal Access Token.
  
## Provider-Specific Prerequisites  
  
### AWS  
  
- **AWS SSH KeyPair**: Create an AWS SSH KeyPair in the region where you'll be bootstrapping the cluster.
  
### Azure  
  
- **System Requirements**: A Linux or MacOS computer with at least 16GB of RAM (8GB might work but may encounter OOM issues).
  
- **Service Principal**: Register an application (Service Principal) in Microsoft Entra ID.  
  
- **SSH Keypairs**:   
  - An OpenSSH type SSH keypair (private key for SSH access to VMs)  
  - A PEM type SSH keypair (for Azure Workload Identity setup)   
  
### Bare Metal  
  
For general bare metal setups (non-Hetzner), only the common dependencies are required. The bare metal provider uses Kubermatic KubeOne under the hood as machine lifecycle management is not needed.   
  
### Hetzner  
  
#### Hetzner HCloud  
  
- **HCloud SSH KeyPair**: Create an HCloud SSH KeyPair. Note that no two HCloud SSH KeyPairs can have the same SSH public key. 
  
#### Hetzner Bare Metal  
  
- **Hetzner Bare Metal SSH KeyPair**: Create a Hetzner Bare Metal SSH KeyPair at https://robot.hetzner.com/key/index. Note that no two Hetzner Bare Metal SSH KeyPairs can have the same SSH public key.   
  
- **RAID Cleanup** (if applicable): If you plan to set `cloud.hetzner.bareMetal.wipeDisks: True` in your configuration, remove any pre-existing RAID setup from your Hetzner Bare Metal servers by executing `wipefs -fa <partition-name>` for each partition.   
  
#### Hetzner Hybrid  
  
Requires both HCloud and Hetzner Bare Metal prerequisites listed above.   
  
### Local K3D  
  
For local testing with K3D, only the common dependencies are required. Note that this setup does not support cluster upgrades and disaster recovery.
  
## Notes  
  
- The cluster setup follows GitOps principles using ArgoCD, ensuring all changes are version-controlled through Git.  
- KubeAid clusters are designed to be private by default, with optional Wireguard gateway for secure access.  
- All providers use Cilium CNI running in kube-proxyless mode for networking.