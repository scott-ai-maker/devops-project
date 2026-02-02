# Terraform Infrastructure

This directory contains Terraform code to provision Azure infrastructure for the DevOps demo project.

## 📁 Structure

```
terraform/
├── main.tf                 # Main configuration and module composition
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars.example # Example variables file
├── backend-setup.sh        # Script to create Azure Storage backend
└── modules/
    ├── resource-group/     # Resource Group module
    ├── acr/                # Azure Container Registry module
    ├── aks/                # Azure Kubernetes Service module
    └── key-vault/          # Azure Key Vault module
```

## 🚀 Quick Start

### 1. Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0 installed
- Azure subscription with appropriate permissions

### 2. Login to Azure

```bash
az login
az account show  # Verify correct subscription
# If needed: az account set --subscription "Your Subscription Name"
```

### 3. Set Up Remote State Backend (First Time Only)

```bash
cd terraform
chmod +x backend-setup.sh
./backend-setup.sh
```

This creates:
- Storage account for Terraform state
- Blob container
- Generates `backend.hcl` configuration

### 4. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Important:** Update these values:
- `acr_name` - Must be globally unique and alphanumeric
- `key_vault_name` - Must be globally unique
- Add your name/initials to make them unique

### 5. Initialize Terraform

```bash
terraform init -backend-config=backend.hcl
```

### 6. Plan and Apply

```bash
# See what will be created
terraform plan

# Create the infrastructure
terraform apply
```

## 🏗️ Resources Created

- **Resource Group**: Container for all resources
- **Azure Container Registry (ACR)**: Docker image registry
- **Azure Kubernetes Service (AKS)**: Managed Kubernetes cluster
  - 2 nodes (Standard_D2s_v3)
  - RBAC enabled
  - Azure CNI networking
  - Integrated with ACR (AcrPull role)
- **Azure Key Vault**: Secrets management

## 📊 Outputs

After `terraform apply`, you'll get:
- ACR login server URL
- AKS cluster name and FQDN
- Key Vault name and URI
- Kubeconfig (sensitive, use `terraform output -raw aks_kube_config_raw`)

## 🔐 Security Best Practices

1. **State File**: Stored remotely in Azure Storage (encrypted)
2. **No Hardcoded Secrets**: All sensitive values via variables or Key Vault
3. **RBAC**: Enabled on AKS with Azure AD integration
4. **Managed Identities**: AKS uses system-assigned identity
5. **Network Policies**: Azure CNI with network policies enabled

## 🧹 Cleanup

To destroy all resources and avoid charges:

```bash
terraform destroy
```

**Warning:** This will delete everything. Make sure to backup any important data.

## 💰 Cost Estimates

Approximate monthly costs (as of 2026):
- AKS (2x Standard_D2s_v3): ~$140/month
- ACR (Basic): ~$5/month
- Key Vault: ~$0.03/month
- **Total**: ~$145/month

To minimize costs:
- Destroy resources when not in use
- Use smaller VM sizes for testing
- Enable autoscaling with min=1 node

## 🔧 Common Commands

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Get outputs
terraform output
terraform output -raw aks_kube_config_raw > ~/.kube/config-demo

# Refresh state
terraform refresh
```

## 📚 Module Documentation

Each module has its own README with detailed information:
- [Resource Group Module](./modules/resource-group/README.md)
- [ACR Module](./modules/acr/README.md)
- [AKS Module](./modules/aks/README.md)
- [Key Vault Module](./modules/key-vault/README.md)

## 🐛 Troubleshooting

### Issue: "ACR name already exists"
**Solution**: Change `acr_name` in `terraform.tfvars` to something unique

### Issue: "Insufficient permissions"
**Solution**: Ensure you have Contributor role on the subscription

### Issue: "Quota exceeded"
**Solution**: Request quota increase or use smaller VM sizes

### Issue: "Backend initialization failed"
**Solution**: Run `backend-setup.sh` first to create storage account
