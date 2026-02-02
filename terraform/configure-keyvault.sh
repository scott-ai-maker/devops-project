#!/bin/bash
# Script to configure Azure Key Vault secrets for the application
# Run this after Terraform completes

set -e

echo "🔐 Configuring Azure Key Vault for DevOps Demo..."

# Variables
KEY_VAULT_NAME="devops-kv-2026"
RESOURCE_GROUP="devops-demo-rg"
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)

# Check if Key Vault exists
if ! az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "❌ Key Vault not found. Ensure Terraform has completed."
    exit 1
fi

echo "✅ Key Vault found: $KEY_VAULT_NAME"
echo ""

# Example secrets to store
echo "📝 Example secrets you might store in Key Vault:"
echo ""
echo "1. Database Connection String"
echo "2. API Keys (external services)"
echo "3. JWT Signing Keys"
echo "4. OAuth Credentials"
echo ""

# Store example secrets
echo "Adding example secrets to Key Vault..."

# Application name
az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "app-name" \
    --value "DevOps Demo API" \
    --description "Application name"

# Environment
az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "environment" \
    --value "production" \
    --description "Deployment environment"

# Log level
az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "log-level" \
    --value "INFO" \
    --description "Application log level"

# ACR Login Server
az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "acr-login-server" \
    --value "$ACR_LOGIN_SERVER" \
    --description "Azure Container Registry login server"

echo ""
echo "✅ Secrets configured!"
echo ""
echo "📋 Secrets in Key Vault:"
az keyvault secret list --vault-name "$KEY_VAULT_NAME" --output table
echo ""
echo "🔑 To retrieve a secret:"
echo "   az keyvault secret show --vault-name '$KEY_VAULT_NAME' --name 'app-name'"
echo ""
echo "🐳 To use secrets in Kubernetes:"
echo "   kubectl create secret generic app-secrets \\"
echo "     --from-literal=app-name=\$(az keyvault secret show \\"
echo "       --vault-name '$KEY_VAULT_NAME' \\"
echo "       --name 'app-name' \\"
echo "       --query value -o tsv)"
echo ""
