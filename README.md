# DevOps Demo Project

A production-ready demonstration of DevOps best practices using Azure, Terraform, Kubernetes, and CI/CD.

## 🎯 Project Overview

This project showcases:
- **FastAPI** web application with health checks and metrics
- **Docker** multi-stage builds with security best practices
- **Terraform** infrastructure as code for Azure
- **Azure Kubernetes Service (AKS)** deployment
- **Helm** charts for Kubernetes orchestration
- **GitHub Actions** CI/CD pipeline
- **Azure Key Vault** for secrets management
- **RBAC** and security best practices

## 🏗️ Architecture

```
┌─────────────────┐
│  GitHub Actions │ (CI/CD)
└────────┬────────┘
         │
    ┌────▼────┐
    │  Build  │
    │ & Push  │
    └────┬────┘
         │
    ┌────▼────────────┐
    │ Azure Container │
    │    Registry     │
    └────┬────────────┘
         │
    ┌────▼──────────────┐
    │  Azure Kubernetes │
    │     Service       │
    │  ┌──────────────┐ │
    │  │   FastAPI    │ │
    │  │     Pods     │ │
    │  └──────────────┘ │
    └───────────────────┘
```

## 🚀 Quick Start

### Local Development

1. **Run with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

2. **Access the API:**
   - API: http://localhost:8000
   - Docs: http://localhost:8000/docs
   - Health: http://localhost:8000/health
   - Metrics: http://localhost:8000/metrics

### Testing the API

```bash
# Health check
curl http://localhost:8000/health

# Send a message
curl -X POST http://localhost:8000/api/message \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello DevOps!"}'

# Get metrics
curl http://localhost:8000/metrics
```

## 📁 Project Structure

```
devops-project/
├── app/                    # Python application
│   ├── main.py
│   └── requirements.txt
├── terraform/              # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
├── helm/                   # Kubernetes Helm charts
│   └── devops-demo/
├── .github/workflows/      # CI/CD pipelines
├── Dockerfile
└── docker-compose.yml
```

## 🔧 Prerequisites

- Docker & Docker Compose
- Azure CLI
- Terraform >= 1.0
- kubectl
- Helm 3
- An Azure subscription

## 📚 Next Steps

1. Set up Azure infrastructure with Terraform
2. Configure GitHub Actions
3. Deploy to AKS
4. Set up monitoring and logging

## 🔐 Security

- Non-root Docker containers
- Multi-stage builds for minimal attack surface
- Azure Key Vault for secrets
- RBAC for Kubernetes
- No hardcoded credentials

## 📝 License

This is a demonstration project for educational purposes.
# devops-project
