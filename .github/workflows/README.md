# GitHub Actions CI/CD Pipeline

This directory contains the GitHub Actions workflows for the DevOps demonstration project.

## Workflows

### `ci-cd.yml` - Main CI/CD Pipeline

A complete production-ready CI/CD pipeline with:

#### 🧪 Build and Test
- Python linting (flake8)
- Unit tests with pytest
- Code coverage reporting
- Runs on every push and PR

#### 🐳 Docker Build & Push
- Multi-stage Docker builds
- Pushes to Azure Container Registry
- Image tagging strategy (SHA, branch, latest)
- Build caching for faster builds
- Vulnerability scanning with Trivy

#### 🏗️ Terraform Plan
- Runs on pull requests
- Validates Terraform code
- Shows infrastructure changes
- Prevents bad deployments

#### 🚀 Deploy to AKS
- Helm-based deployment
- Only on main branch pushes
- Uses production environment protection
- Automatic rollback on failure (`--atomic`)
- Health checks after deployment

#### ✅ Smoke Tests
- Post-deployment validation
- Tests all API endpoints
- Ensures deployment is functional

## Required Secrets

Configure these in GitHub Settings → Secrets and variables → Actions:

### Azure Credentials
```bash
# Create Service Principal
az ad sp create-for-rbac \
  --name "github-actions-devops-demo" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/devops-demo-rg \
  --sdk-auth

# Copy the JSON output to GitHub Secret: AZURE_CREDENTIALS
```

### ACR Credentials
```bash
# Get ACR credentials
az acr credential show --name devopsdemoacr2026

# Add to GitHub Secrets:
# ACR_USERNAME: username from above
# ACR_PASSWORD: password from above
```

## GitHub Secrets Summary

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `AZURE_CREDENTIALS` | Service Principal JSON | `az ad sp create-for-rbac --sdk-auth` |
| `ACR_USERNAME` | ACR admin username | `az acr credential show` |
| `ACR_PASSWORD` | ACR admin password | `az acr credential show` |

## Workflow Triggers

```yaml
# Automatic triggers
push:
  branches: [ main, develop ]  # Deploy on push to these branches

pull_request:
  branches: [ main ]           # Test on PRs to main

# Manual trigger
workflow_dispatch:             # Run manually from GitHub UI
```

## Environment Protection

The `production` environment has:
- Deployment approvals (optional)
- Environment-specific secrets
- Deployment history tracking

## Pipeline Flow

```
┌─────────────────────┐
│   Code Push/PR      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Build & Test       │  ← Lint, test, coverage
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Docker Build       │  ← Build image, scan vulnerabilities
│  & Push to ACR      │
└──────────┬──────────┘
           │
           ▼ (main branch only)
┌─────────────────────┐
│  Deploy to AKS      │  ← Helm upgrade
│  with Helm          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Smoke Tests        │  ← Verify deployment
└─────────────────────┘
```

## Local Testing

Test the pipeline steps locally:

```bash
# Run tests
pytest app/ --cov=app

# Build Docker image
docker build -t devops-demo:local .

# Test Helm chart
helm lint helm/devops-demo
helm template devops-demo helm/devops-demo --debug

# Validate Terraform
cd terraform && terraform validate
```

## Monitoring Pipeline

### View Pipeline Status
- GitHub Actions tab in repository
- Commit status checks
- Environment deployment history

### Pipeline Metrics
- Build time
- Test coverage
- Deployment frequency
- Success rate

## Troubleshooting

### Build Failures
```bash
# Check logs in GitHub Actions UI
# Common issues:
- Linting errors → Fix code formatting
- Test failures → Fix tests
- Docker build errors → Check Dockerfile
```

### Deployment Failures
```bash
# Check Helm deployment
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Check service
kubectl get svc
kubectl describe svc devops-demo
```

### ACR Authentication Issues
```bash
# Verify ACR credentials
az acr login --name devopsdemoacr2026

# Check service principal permissions
az role assignment list --assignee <service-principal-id>
```

## Best Practices Implemented

✅ **Fail Fast** - Tests run before deployment  
✅ **Atomic Deployments** - Auto-rollback on failure  
✅ **Security Scanning** - Trivy scans for vulnerabilities  
✅ **Immutable Tags** - Use SHA for image tags  
✅ **Health Checks** - Verify deployment before marking success  
✅ **Secrets Management** - No hardcoded credentials  
✅ **Environment Isolation** - Separate dev/prod environments  
✅ **Audit Trail** - All deployments logged in GitHub  

## Future Enhancements

- [ ] Add staging environment
- [ ] Implement blue-green deployments
- [ ] Add performance testing
- [ ] Integrate with monitoring (Prometheus/Grafana)
- [ ] Add Slack/Teams notifications
- [ ] Implement automatic rollback triggers
- [ ] Add database migration steps
- [ ] Security compliance scanning
