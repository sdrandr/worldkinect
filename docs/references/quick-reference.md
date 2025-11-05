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

---

[Add more quick reference commands]
