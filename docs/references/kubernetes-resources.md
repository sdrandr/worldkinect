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

[Add more K8s resource details]
