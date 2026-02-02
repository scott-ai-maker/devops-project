# Security Configuration Guide

This guide covers security best practices implemented in the project.

## 🔐 Overview

Security is implemented at multiple layers:
1. **Infrastructure** - Azure RBAC, VNet isolation
2. **Container** - Non-root user, dropped capabilities
3. **Kubernetes** - Pod Security Policies, Network Policies
4. **Secrets** - Azure Key Vault, Kubernetes Secrets
5. **Access Control** - RBAC, Service Accounts

## 🛡️ Container Security

### Non-Root User
```dockerfile
RUN useradd -m -u 1000 appuser
USER appuser
```
- Application runs as user 1000 (not root)
- Limits blast radius of container escape

### Dropped Capabilities
```yaml
securityContext:
  capabilities:
    drop:
    - ALL
```
- Removes all Linux capabilities
- Application only gets what it needs

### Read-Only Filesystem
```yaml
readOnlyRootFilesystem: false  # Set to true for hardened setup
```
- Prevents writing to root filesystem
- Forces use of temporary directories

## 🔑 Secrets Management

### Azure Key Vault
```bash
# Store secrets
az keyvault secret set --vault-name devops-kv-2026 --name api-key --value "..."

# Retrieve secrets
az keyvault secret show --vault-name devops-kv-2026 --name api-key
```

### Kubernetes Secrets
```bash
# Create secret from literal values
kubectl create secret generic app-secrets \
  --from-literal=database-url="..." \
  --from-literal=api-key="..."

# Reference in deployment
envFrom:
- secretRef:
    name: app-secrets
```

## 🚫 Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: devops-demo-network-policy
spec:
  podSelector:
    matchLabels:
      app: devops-demo
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

**What it does:**
- Only allows traffic from specific pods
- Only allows outbound to specific services
- Default-deny everything else

## 📋 RBAC (Role-Based Access Control)

### Service Account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: devops-demo
```

### Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: devops-demo-role
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
```

### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devops-demo-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: devops-demo-role
subjects:
- kind: ServiceAccount
  name: devops-demo
  namespace: default
```

## 🔐 Azure-Level Security

### Network Security Groups (NSG)
```bash
# Already configured by Terraform with:
# - Inbound: Allow from AKS subnet only
# - Outbound: Allow to Azure services
```

### Azure RBAC
```bash
# AKS system identity has minimal required permissions:
az role assignment list --scope /subscriptions/... | grep -i aks
```

### Private Endpoints (Optional)
```hcl
# Can be added to ACR and Key Vault
# Restricts access to AKS vnet only
```

## 📝 Secrets Best Practices

### ✅ DO:
- Store secrets in Azure Key Vault
- Use managed identities (not connection strings)
- Rotate secrets regularly
- Audit secret access
- Use different secrets for each environment
- Never commit secrets to Git

### ❌ DON'T:
- Hardcode secrets in code
- Store secrets in environment variables (use Secrets)
- Share secrets across environments
- Log secrets in error messages
- Use overly permissive RBAC

## 🔍 Audit and Monitoring

### Enable Audit Logs
```bash
# Azure Activity Log
az monitor activity-log list \
  --resource-group devops-demo-rg \
  --query '[0:5].[eventName, resourceGroup, resourceProvider]' \
  --output table
```

### Monitor Secret Access
```bash
# Key Vault audit logs
az monitor diagnostic-settings create \
  --name keyvault-audit \
  --resource /subscriptions/.../providers/Microsoft.KeyVault/vaults/devops-kv-2026 \
  --logs '[{"category":"AuditEvent","enabled":true}]'
```

### Kubernetes Audit Logs
```bash
# Check who accessed what
kubectl describe auditpolicy
```

## 🚀 Security Checklist

- [ ] Non-root containers running
- [ ] Capabilities dropped in containers
- [ ] Secrets in Key Vault, not hardcoded
- [ ] Pod Security Policies enforced
- [ ] Network Policies implemented
- [ ] RBAC configured with least privilege
- [ ] Service Accounts created per app
- [ ] Audit logging enabled
- [ ] Regular security patches applied
- [ ] Secrets rotated regularly (every 90 days)
- [ ] Image scanning enabled in ACR
- [ ] TLS enabled for all communication
- [ ] Resource quotas configured
- [ ] Pod Disruption Budgets defined
- [ ] Network segmentation in place

## 🛠️ Hardening Terraform

Add to `terraform/variables.tf`:
```hcl
variable "enable_network_policy" {
  default = true
}

variable "pod_security_policy_enabled" {
  default = true
}
```

Update AKS module `terraform/modules/aks/main.tf`:
```hcl
network_policy = var.enable_network_policy ? "azure" : "kubenet"

# Add Pod Security Policy (deprecated in K8s 1.25+ but useful for 1.19-1.24)
pod_security_policy_enabled = var.pod_security_policy_enabled
```

## 🔗 References

- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Container Security](https://kubernetes.io/docs/concepts/security/pod-security-policy/)
- [OWASP Cheat Sheet](https://cheatsheetseries.owasp.org/)
