# 🚀 SDRANDR mock Wk Accounts API

GraphQL subgraph service for accounts management, deployed on AWS EKS with Apollo Federation.

---

## 📚 Documentation

**Complete documentation is available in the [docs/](./docs/) folder.**

### Quick Links

- **[Getting Started Guide](docs/guides/01-iam-setup.md)** - Set up IAM and permissions
- **[Two-Account Setup](docs/guides/02-two-account-setup.md)** - Managing admin and working accounts
- **[EKS Migration Guide](docs/guides/03-eks-migration.md)** - Migrate from Lambda to EKS
- **[CI/CD Automation](docs/guides/05-cicd-automation.md)** - Automated deployments
- **[Quick Reference](docs/reference/quick-reference.md)** - Common commands cheat sheet

---

## ⚡ Quick Start

```bash
# 1. Verify IAM permissions
./scripts/verify-terraform-admin.sh

# 2. Setup for EKS deployment
./scripts/setup-accounts-api-eks.sh

# 3. Deploy to development
./scripts/ci-cd-pipeline.sh

# 4. Deploy to other environments
./scripts/ci-cd-pipeline.sh --env staging
./scripts/ci-cd-pipeline.sh --env prod
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Users / React Applications                  │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│         Apollo Router (EKS - Federation Gateway)        │
│         - Single GraphQL endpoint                        │
│         - Routes queries to subgraphs                    │
│         - Caching and monitoring                         │
└──────────────────────┬──────────────────────────────────┘
                       │
               ┌───────┴────────┐
               ▼                ▼
┌─────────────────────┐  ┌─────────────────────┐
│   Accounts Subgraph │  │  Other Subgraphs    │
│       (EKS)         │  │      (EKS)          │
│  - TypeScript       │  │  - Products         │
│  - Apollo Server    │  │  - Orders           │
│  - GraphQL          │  │  - etc.             │
└─────────────────────┘  └─────────────────────┘
```

---

## 🛠️ Technology Stack

- **Language:** TypeScript
- **GraphQL:** Apollo Server, Apollo Federation
- **Runtime:** Node.js 20+
- **Platform:** AWS EKS (Kubernetes)
- **Container:** Docker
- **CI/CD:** GitHub Actions, Jenkins
- **IaC:** Terraform
- **Registry:** AWS ECR

---

## 📁 Project Structure

```
worldkinect/
├── docs/                           # Complete documentation
│   ├── guides/                     # Step-by-step guides
│   ├── workflows/                  # CI/CD workflows
│   └── reference/                  # Reference materials
├── scripts/                        # Deployment scripts
│   ├── setup-accounts-api-eks.sh  # Initial setup
│   ├── build-and-push.sh          # Build & push Docker image
│   ├── deploy-to-eks.sh           # Deploy to EKS
│   └── ci-cd-pipeline.sh          # Full CI/CD pipeline
├── services/
│   └── accounts-api/              # Accounts service
│       ├── src/                   # TypeScript source
│       ├── kubernetes/            # K8s manifests
│       ├── Dockerfile             # Container definition
│       └── package.json
├── terraform/                     # Infrastructure as Code
│   ├── environments/              # Environment configs
│   └── modules/                   # Terraform modules
└── .github/
    └── workflows/                 # GitHub Actions
```

---

## 🚦 Environments

| Environment | Branch | Cluster | Namespace | Auto-Deploy |
|-------------|--------|---------|-----------|-------------|
| Development | `main` | `worldkinect-dev` | `default` | ✅ Yes |
| Staging | `staging` | `worldkinect-staging` | `staging` | ✅ Yes |
| Production | `production` | `worldkinect-prod` | `production` | ⚠️ Manual approval |

---

## 🔐 Prerequisites

### Local Development (Mac)
- AWS CLI configured with `terraform-admin` credentials
- kubectl configured for EKS access
- Docker Desktop running
- Node.js 20+

### AWS Resources
- IAM user: `terraform-admin` (for deployments)
- EKS clusters provisioned
- ECR repository created
- Proper IAM roles and policies

See [IAM Setup Guide](docs/guides/01-iam-setup.md) for complete details.

---

## 📖 Common Tasks

### Deploy to Development
```bash
./scripts/ci-cd-pipeline.sh
```

### Deploy to Staging
```bash
./scripts/ci-cd-pipeline.sh --env staging
```

### Build Docker Image
```bash
./scripts/build-and-push.sh
```

### View Logs
```bash
kubectl logs -l app=accounts-api -f
```

### Rollback Deployment
```bash
kubectl rollout undo deployment/accounts-api
```

See [Quick Reference](docs/reference/quick-reference.md) for more commands.

---

## 🧪 Testing

### Local Testing
```bash
cd services/accounts-api

# Install dependencies
npm install

# Run tests
npm test

# Type checking
npm run type-check

# Linting
npm run lint

# Run locally
npm run dev
```

### Docker Testing
```bash
# Build and test
npm run docker:build
npm run docker:run

# Test health endpoint
curl http://localhost:4000/.well-known/apollo/server-health
```

---

## 🔍 Monitoring

```bash
# View pod status
kubectl get pods -l app=accounts-api

# View service
kubectl get svc accounts-api

# View HPA (auto-scaling)
kubectl get hpa accounts-api-hpa

# Port forward for local testing
kubectl port-forward svc/accounts-api 4000:4000
```

---

## 🐛 Troubleshooting

Common issues and solutions are documented in:
- [Troubleshooting Guide](docs/reference/troubleshooting.md)
- [Quick Reference](docs/reference/quick-reference.md)

**Quick diagnostics:**
```bash
# Check AWS identity
aws sts get-caller-identity

# Verify terraform-admin permissions
./scripts/verify-terraform-admin.sh

# Check pod status
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>
```

---

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes
3. Test locally: `npm test && npm run type-check`
4. Commit with clear message
5. Push and create PR
6. After approval, merge to `main` (auto-deploys to dev)

---

## 📞 Support

- **Documentation:** [docs/](./docs/)
- **Issues:** GitHub Issues
- **Team Channel:** Slack #accounts-api

---

## 📝 License

Copyright © WorldKinect Corporation. All rights reserved.

---

**Last Updated:** $(date +"%Y-%m-%d")