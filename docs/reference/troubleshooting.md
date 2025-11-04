# Troubleshooting Guide

## Common Issues

### Issue: "Access Denied" Errors

**Symptom:** AWS CLI commands fail with access denied

**Solution:**
```bash
# Check current user
aws sts get-caller-identity

# Should show terraform-admin
# If not, switch profile:
export AWS_PROFILE=default

# Verify permissions
./scripts/verify-terraform-admin.sh
```

---

### Issue: Pod Won't Start

**Symptom:** Pods stuck in Pending or CrashLoopBackOff

**Diagnosis:**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

**Common Causes:**
- Image pull errors (check ECR permissions)
- Resource limits too low
- Missing environment variables
- Health check failures

---

### Issue: Image Pull Errors

**Symptom:** `ErrImagePull` or `ImagePullBackOff`

**Solution:**
```bash
# Verify image exists
aws ecr describe-images --repository-name worldkinect/accounts-api

# Check image name in deployment
kubectl get deployment accounts-api -o yaml | grep image

# Verify ECR permissions for EKS nodes
```

---

### Issue: Health Check Failures

**Symptom:** Pods restarting, readiness probe failing

**Solution:**
```bash
# Test health endpoint from inside pod
kubectl exec -it <pod-name> -- curl http://localhost:4000/.well-known/apollo/server-health

# Check if Apollo Server started
kubectl logs <pod-name> | grep "ready at"

# Check application logs for errors
kubectl logs <pod-name>
```

---

### Issue: Can't Connect to EKS

**Symptom:** `kubectl` commands fail with connection errors

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name worldkinect-dev --region us-east-1

# Verify connection
kubectl cluster-info

# Check AWS permissions
aws eks describe-cluster --name worldkinect-dev
```

---

### Issue: GitHub Actions Deployment Fails

**Symptom:** GitHub Actions workflow fails

**Solution:**
1. Check GitHub Secrets are set correctly
2. Verify AWS credentials have required permissions
3. Check workflow logs for specific error
4. Test deployment locally first

---

[Add more troubleshooting scenarios]
