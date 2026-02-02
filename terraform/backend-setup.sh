#!/bin/bash
# Script to set up Azure Storage backend for Terraform state
# Run this ONCE before your first terraform init

set -e

echo "🔧 Setting up Terraform Backend in Azure Storage..."

# Variables - customize these
RESOURCE_GROUP_NAME="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstate$(openssl rand -hex 4)"  # Generates unique name
CONTAINER_NAME="tfstate"
LOCATION="eastus"

echo "📦 Resource Group: $RESOURCE_GROUP_NAME"
echo "💾 Storage Account: $STORAGE_ACCOUNT_NAME"
echo "📂 Container: $CONTAINER_NAME"
echo "🌍 Location: $LOCATION"
echo ""

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Run 'az login' first."
    exit 1
fi

# Create resource group
echo "Creating resource group..."
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags "purpose=terraform-state" "managed-by=script"

# Create storage account
echo "Creating storage account..."
az storage account create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --sku Standard_LRS \
    --encryption-services blob \
    --location "$LOCATION" \
    --tags "purpose=terraform-state"

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

# Create blob container
echo "Creating blob container..."
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$ACCOUNT_KEY"

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "📝 Create a file 'backend.hcl' with these values:"
echo "----------------------------------------"
cat << EOF
resource_group_name  = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
key                  = "devops-demo.tfstate"
EOF
echo "----------------------------------------"
echo ""
echo "Then initialize Terraform with:"
echo "  terraform init -backend-config=backend.hcl"
echo ""
