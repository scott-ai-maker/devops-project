# DevOps Demo Helm Chart

A production-ready Helm chart for deploying the DevOps Demo API to Kubernetes.

## Features

- ✅ **Horizontal Pod Autoscaling** (HPA) based on CPU/Memory
- ✅ **Health Checks** (Liveness & Readiness probes)
- ✅ **Resource Limits** (CPU/Memory requests and limits)
- ✅ **Security** (Non-root user, dropped capabilities, security context)
- ✅ **High Availability** (Multiple replicas, Pod Disruption Budget)
- ✅ **ConfigMaps** for configuration management
- ✅ **Service Account** with RBAC
- ✅ **Ingress** support (optional)
- ✅ **Load Balancer** support (Azure LB)

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Azure Kubernetes Service (AKS) or any K8s cluster
- Container image pushed to ACR

## Installation

### Quick Install

```bash
# Add your image repository
helm install devops-demo ./helm/devops-demo \
  --set image.repository=devopsdemoacr2026.azurecr.io/devops-demo \
  --set image.tag=v1.0.0
```

### Install with Custom Values

```bash
# Create a custom values file
cat > my-values.yaml <<EOF
replicaCount: 3
image:
  repository: devopsdemoacr2026.azurecr.io/devops-demo
  tag: v1.0.0
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 20
EOF

# Install with custom values
helm install devops-demo ./helm/devops-demo -f my-values.yaml
```

## Configuration

The following table lists the configurable parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `devopsdemoacr2026.azurecr.io/devops-demo` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Service type | `LoadBalancer` |
| `service.port` | Service port | `80` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `250m` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Min replicas | `2` |
| `autoscaling.maxReplicas` | Max replicas | `10` |
| `ingress.enabled` | Enable ingress | `false` |

See [values.yaml](values.yaml) for all available options.

## Usage Examples

### Get Service External IP

```bash
kubectl get svc devops-demo -w
```

### Test the API

```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get svc devops-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test health endpoint
curl http://$EXTERNAL_IP/health

# Test API
curl -X POST http://$EXTERNAL_IP/api/message \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Kubernetes!"}'
```

### View Logs

```bash
kubectl logs -f deployment/devops-demo
```

### Scale Manually

```bash
kubectl scale deployment devops-demo --replicas=5
```

### Watch HPA

```bash
kubectl get hpa devops-demo -w
```

## Upgrading

```bash
# Upgrade with new image
helm upgrade devops-demo ./helm/devops-demo \
  --set image.tag=v1.1.0 \
  --reuse-values
```

## Uninstalling

```bash
helm uninstall devops-demo
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=devops-demo

# Describe pod
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### Service has no external IP

```bash
# Check service
kubectl describe svc devops-demo

# For Azure, ensure AKS has proper permissions
```

### Image pull errors

```bash
# Verify ACR integration
az aks check-acr --resource-group devops-demo-rg \
  --name devops-demo-aks \
  --acr devopsdemoacr2026.azurecr.io
```

## Production Checklist

- [ ] Set appropriate resource limits
- [ ] Configure autoscaling thresholds
- [ ] Enable Pod Disruption Budget
- [ ] Set up monitoring/alerting
- [ ] Configure ingress with TLS
- [ ] Use secrets for sensitive data
- [ ] Set up backup strategy
- [ ] Configure network policies
- [ ] Enable logging aggregation
- [ ] Set up CI/CD pipeline

## Contributing

This chart is part of the DevOps Demo project.
