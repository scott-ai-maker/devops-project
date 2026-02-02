# 🚀 DevOps Project - Complete Setup Guide

This guide walks you through deploying the entire project to Azure.

## Prerequisites ✅

- [x] Azure subscription
- [x] Azure CLI installed
- [x] Terraform installed
- [x] Docker installed
- [x] kubectl installed
- [x] Helm 3 installed
- [x] GitHub account

## Phase 1: Infrastructure Deployment

### 1.1 Verify Terraform Apply Status

```bash
cd terraform

# Check if apply is still running
ps aux | grep terraform

# If complete, verify outputs
terraform output
```

### 1.2 Save Important Outputs

```bash
# Get ACR login server
export ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
echo "ACR: $ACR_LOGIN_SERVER"

# Get AKS credentials
az aks get-credentials \
  --resource-group devops-demo-rg \
  --name devops-demo-aks \
  --overwrite-existing

# Verify connection
kubectl get nodes
```

## Phase 2: Build and Push Docker Image

### 2.1 Login to ACR

```bash
# Login to Azure Container Registry
az acr login --name devopsdemoacr2026

# Verify login
docker info | grep -A 5 Registry
```

### 2.2 Build and Push Image

```bash
cd /home/scott/repos/devops-project

# Build the image
docker build -t devopsdemoacr2026.azurecr.io/devops-demo:v1.0.0 .

# Test image locally (optional)
docker run -p 8000:8000 devopsdemoacr2026.azurecr.io/devops-demo:v1.0.0

# Push to ACR
docker push devopsdemoacr2026.azurecr.io/devops-demo:v1.0.0

# Tag as latest
docker tag devopsdemoacr2026.azurecr.io/devops-demo:v1.0.0 \
           devopsdemoacr2026.azurecr.io/devops-demo:latest

docker push devopsdemoacr2026.azurecr.io/devops-demo:latest

# Verify images in ACR
az acr repository list --name devopsdemoacr2026 --output table
az acr repository show-tags --name devopsdemoacr2026 \
  --repository devops-demo --output table
```

## Phase 3: Deploy to Kubernetes with Helm

### 3.1 Verify AKS Connection

```bash
# Check nodes are ready
kubectl get nodes

# Check if you have access
kubectl get namespaces
```

### 3.2 Install with Helm

```bash
# Navigate to project root
cd /home/scott/repos/devops-project

# Lint the Helm chart
helm lint helm/devops-demo

# Dry run to see what will be deployed
helm install devops-demo ./helm/devops-demo \
  --set image.repository=devopsdemoacr2026.azurecr.io/devops-demo \
  --set image.tag=v1.0.0 \
  --dry-run --debug

# Deploy for real
helm install devops-demo ./helm/devops-demo \
  --set image.repository=devopsdemoacr2026.azurecr.io/devops-demo \
  --set image.tag=v1.0.0 \
  --wait

# Check deployment status
helm list
kubectl get pods -w
```

### 3.3 Get Service External IP

```bash
# Watch for LoadBalancer IP (takes 2-3 minutes)
kubectl get svc devops-demo-devops-demo -w

# Once EXTERNAL-IP appears, save it
export SERVICE_IP=$(kubectl get svc devops-demo-devops-demo \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Service available at: http://$SERVICE_IP"
```

### 3.4 Test the Deployment

```bash
# Test health endpoint
curl http://$SERVICE_IP/health

# Test API documentation
echo "Swagger UI: http://$SERVICE_IP/docs"
xdg-open http://$SERVICE_IP/docs  # Opens in browser

# Test API endpoint
curl -X POST http://$SERVICE_IP/api/message \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Kubernetes!"}'

# Check metrics
curl http://$SERVICE_IP/metrics
```

## Phase 4: Setup GitHub Actions CI/CD

### 4.1 Create Service Principal for GitHub

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-devops-demo" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/devops-demo-rg \
  --sdk-auth

# ⚠️ SAVE THE JSON OUTPUT - You'll need it for GitHub Secrets
```

### 4.2 Get ACR Credentials

```bash
# Enable admin user on ACR (needed for GitHub Actions)
az acr update --name devopsdemoacr2026 --admin-enabled true

# Get credentials
az acr credential show --name devopsdemoacr2026

# ⚠️ SAVE:
# - username (ACR_USERNAME)
# - password (ACR_PASSWORD)
```

### 4.3 Configure GitHub Secrets

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

| Secret Name | Value | Source |
|------------|-------|--------|
| `AZURE_CREDENTIALS` | Entire JSON output | Service Principal creation |
| `ACR_USERNAME` | Username from ACR | `az acr credential show` |
| `ACR_PASSWORD` | Password from ACR | `az acr credential show` |

### 4.4 Initialize Git Repository

```bash
cd /home/scott/repos/devops-project

# Initialize git (if not already)
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Complete DevOps project"

# Add GitHub remote (replace with your repo URL)
git remote add origin https://github.com/YOUR-USERNAME/devops-project.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### 4.5 Trigger Pipeline

The pipeline will run automatically on push! Watch it in:
- GitHub → Actions tab

Or trigger manually:
- Actions → CI/CD Pipeline → Run workflow

## Phase 5: Monitoring and Management

### 5.1 Watch Pods and Services

```bash
# Watch all pods
kubectl get pods -A -w

# Describe a pod
kubectl describe pod <pod-name>

# View logs
kubectl logs -f deployment/devops-demo-devops-demo

# Watch autoscaling
kubectl get hpa -w
```

### 5.2 Update the Application

```bash
# Make code changes
# Build new image
docker build -t devopsdemoacr2026.azurecr.io/devops-demo:v1.1.0 .
docker push devopsdemoacr2026.azurecr.io/devops-demo:v1.1.0

# Upgrade with Helm
helm upgrade devops-demo ./helm/devops-demo \
  --set image.tag=v1.1.0 \
  --reuse-values

# Or just push to GitHub and let CI/CD handle it!
git push
```

### 5.3 Scale the Application

```bash
# Manual scaling
kubectl scale deployment devops-demo-devops-demo --replicas=5

# Check HPA status
kubectl get hpa

# Generate load to test autoscaling
kubectl run -it --rm load-generator --image=busybox /bin/sh
# Inside the pod:
while true; do wget -q -O- http://devops-demo-devops-demo/; done
```

## Troubleshooting 🔧

### Pods not starting

```bash
# Check pod status
kubectl get pods

# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Common issues:
# - ImagePullBackOff: Check ACR permissions
# - CrashLoopBackOff: Check application logs
```

### LoadBalancer has no External IP

```bash
# Check service
kubectl describe svc devops-demo-devops-demo

# Verify AKS networking
az aks show -g devops-demo-rg -n devops-demo-aks --query networkProfile
```

### Cannot pull from ACR

```bash
# Verify ACR integration
az aks check-acr \
  --resource-group devops-demo-rg \
  --name devops-demo-aks \
  --acr devopsdemoacr2026.azurecr.io

# Check role assignment
az role assignment list --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/devops-demo-rg
```

## Cleanup 🧹

### Delete Kubernetes Resources

```bash
# Uninstall Helm release
helm uninstall devops-demo

# Verify deletion
kubectl get all
```

### Destroy Azure Infrastructure

```bash
cd terraform

# Preview what will be deleted
terraform plan -destroy

# Destroy everything
terraform destroy

# Confirm with: yes
```

### Estimated Costs

- **Running**: ~$140/month (AKS + ACR + Key Vault)
- **Stopped**: ~$5/month (ACR storage only)
- **Destroyed**: $0/month

## Next Steps 🚀

1. ✅ Verify Terraform applied successfully
2. ✅ Build and push Docker image to ACR
3. ✅ Deploy with Helm to AKS
4. ✅ Test the application
5. ✅ Setup GitHub Actions secrets
6. ✅ Push code to trigger CI/CD

## Success Criteria ✨

- [ ] Application accessible via LoadBalancer IP
- [ ] Pods are healthy and running
- [ ] Autoscaling is configured
- [ ] CI/CD pipeline passes
- [ ] Can update application via Git push

---

**Questions or Issues?** Check the README files in each directory or open an issue on GitHub.
