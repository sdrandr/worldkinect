# Quick Reference

## Daily Commands

```bash
# Check AWS identity
aws sts get-caller-identity

# Deploy to dev
./scripts/ci-cd-pipeline.sh

# Build and push
./scripts/build-and-push.sh

# Deploy to EKS
./scripts/deploy-to-eks.sh
```

## Kubernetes Commands

```bash
# Get pods
kubectl get pods -l app=accounts-api

# View logs
kubectl logs -l app=accounts-api -f

# Describe pod
kubectl describe pod <pod-name>

# Port forward
kubectl port-forward svc/accounts-api 4000:4000

# Restart deployment
kubectl rollout restart deployment/accounts-api

# Rollback
kubectl rollout undo deployment/accounts-api
```

## Docker Commands

```bash
# Build image
docker build -t accounts-api:latest .

# Run locally
docker run -p 4000:4000 accounts-api:latest

# View images
docker images | grep accounts-api

# Remove old images
docker image prune
```

## AWS Commands

```bash
# List ECR images
aws ecr describe-images --repository-name worldkinect/accounts-api

# List EKS clusters
aws eks list-clusters

# Update kubeconfig
aws eks update-kubeconfig --name worldkinect-dev

# ECR login
aws ecr get-login-password | docker login --username AWS --password-stdin <ecr-uri>
```

## Environment Variables

```bash
# Set environment
export ENVIRONMENT=dev
export AWS_REGION=us-east-1
export K8S_NAMESPACE=default
export EKS_CLUSTER_NAME=worldkinect-dev

# For staging
export ENVIRONMENT=staging
export K8S_NAMESPACE=staging
export EKS_CLUSTER_NAME=worldkinect-staging

# For production
export ENVIRONMENT=prod
export K8S_NAMESPACE=production
export EKS_CLUSTER_NAME=worldkinect-prod
```

## Troubleshooting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Get pod logs
kubectl logs <pod-name>

# Get previous pod logs (if crashed)
kubectl logs <pod-name> --previous

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Test from inside pod
kubectl exec -it <pod-name> -- curl http://localhost:4000/.well-known/apollo/server-health
```

## Git Commands

```bash
# Check status
git status

# View recent commits
git log --oneline -10

# Create feature branch
git checkout -b feature/my-feature

# Commit changes
git add .
git commit -m "feat: add new feature"

# Push to remote
git push origin main

# Pull latest changes
git pull origin main
```

## Testing Commands

```bash
# Run tests
cd services/accounts-api && npm test

# Run with coverage
npm run test:coverage

# Type check
npm run type-check

# Lint code
npm run lint

# Fix linting issues
npm run lint:fix
```

## Monitoring & Logs

```bash
# Watch pod status
kubectl get pods -w -l app=accounts-api

# Stream all pod logs
kubectl logs -l app=accounts-api -f --all-containers=true

# View deployment status
kubectl rollout status deployment/accounts-api

# Check resource usage
kubectl top pods -l app=accounts-api

# View HPA status
kubectl get hpa accounts-api-hpa --watch
```

## Database Commands (Future)

```bash
# Connect to database (when integrated)
# psql $DATABASE_URL

# Run migrations (when using TypeORM/Prisma)
# npm run migrate

# Seed database
# npm run seed
```

## Common Workflows

### Deploy to Development
```bash
./scripts/ci-cd-pipeline.sh
```

### Deploy to Staging
```bash
./scripts/ci-cd-pipeline.sh --env staging
```

### Deploy to Production
```bash
./scripts/ci-cd-pipeline.sh --env prod
```

### Quick Local Test
```bash
cd services/accounts-api
npm install
npm run dev
```

### Emergency Rollback
```bash
kubectl rollout undo deployment/accounts-api
kubectl rollout status deployment/accounts-api
```

## Useful Aliases

Add these to your `~/.zshrc` or `~/.bash_profile`:

```bash
# Navigation
alias wk='cd ~/worldkinect'
alias wka='cd ~/worldkinect/services/accounts-api'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -l app=accounts-api'
alias klogs='kubectl logs -l app=accounts-api -f'
alias kpf='kubectl port-forward'

# AWS
alias awswho='aws sts get-caller-identity'

# Development
alias adt='cd ~/worldkinect/services/accounts-api && npm test'
alias adev='cd ~/worldkinect/services/accounts-api && npm run dev'
```
