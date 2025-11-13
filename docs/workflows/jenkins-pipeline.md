# Jenkins Pipeline

## Setup

1. Add AWS credentials to Jenkins
2. Create new Pipeline job
3. Point to `jenkins/Jenkinsfile`
4. Configure parameters

## Parameters

- **ENVIRONMENT:** dev / staging / prod
- **SKIP_TESTS:** Skip test stage
- **DRY_RUN:** Test without deploying

## Running

1. Click "Build with Parameters"
2. Select environment
3. Run build

---

## Pipeline Stages

The Jenkinsfile defines these stages:

1. **Checkout** - Clone repository
2. **Setup** - Verify prerequisites
3. **Lint** - Code quality checks
4. **Test** - Run tests
5. **Build** - Build Docker image
6. **Push** - Push to ECR
7. **Deploy** - Deploy to EKS
8. **Verify** - Health checks

## Pipeline Parameters

- **ENVIRONMENT** - Target environment (dev/staging/prod)
- **IMAGE_TAG** - Docker image tag (default: latest)
- **SKIP_TESTS** - Skip test stage (true/false)
- **DRY_RUN** - Run without deploying (true/false)

## Viewing Build Logs

1. Click on build number
2. Click **Console Output**
3. View detailed logs

## Troubleshooting Jenkins

### Build Fails to Start

- Check Jenkins agent is online
- Verify Git repository access
- Check AWS credentials are configured

### Deployment Fails

- Review deployment logs
- Check EKS cluster access
- Verify IAM permissions

---

## Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Jenkins AWS Plugin](https://plugins.jenkins.io/aws-credentials/)
- [Jenkinsfile Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
