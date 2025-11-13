# Kubernetes Resources Reference

## Deployment

**File:** `services/accounts-api/kubernetes/deployment.yaml`

**Resources:**
- Deployment: 2 replicas, rolling update
- Service: ClusterIP on port 4000
- HorizontalPodAutoscaler: 2-10 replicas based on CPU/memory

**Configuration:**
```yaml
replicas: 2
resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m
```

---

## ServiceAccount

**File:** `services/accounts-api/kubernetes/serviceaccount.yaml`

**Purpose:** IRSA (IAM Roles for Service Accounts)

**Resources:**
- ServiceAccount with IAM role annotation
- Role with configmap/secret permissions
- RoleBinding

---

## Common Commands

### View Resources

```bash
# Get all resources
kubectl get all -l app=accounts-api

# Get deployment
kubectl get deployment accounts-api

# Get service
kubectl get svc accounts-api

# Get pods
kubectl get pods -l app=accounts-api

# Get HPA
kubectl get hpa accounts-api-hpa
```

### Describe Resources

```bash
# Deployment details
kubectl describe deployment accounts-api

# Service details
kubectl describe svc accounts-api

# Pod details
kubectl describe pod <pod-name>
```

### Update Resources

```bash
# Apply changes
kubectl apply -f services/accounts-api/kubernetes/

# Update image
kubectl set image deployment/accounts-api accounts-api=<new-image>

# Scale manually
kubectl scale deployment/accounts-api --replicas=3
```

---

## Resource Limits

**Current Configuration:**
- Memory Request: 256Mi
- Memory Limit: 512Mi
- CPU Request: 250m (0.25 cores)
- CPU Limit: 500m (0.5 cores)

**Monitoring:**
```bash
# Check resource usage
kubectl top pods -l app=accounts-api

# View HPA metrics
kubectl get hpa accounts-api-hpa
```

---

## Resources

- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
