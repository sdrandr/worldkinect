# GitHub Actions Workflow

## Setup

1. Add secrets to GitHub:
   - `Settings > Secrets and variables > Actions`
   - Add: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

2. Copy workflow file:
   ```bash
   mkdir -p .github/workflows
   # Copy artifact: "GitHub Actions Workflow - Deploy to EKS"
   ```

3. Push to trigger:
   ```bash
   git push origin main  # deploys to dev
   ```

## Workflow Triggers

- `push` to `main` → deploys to dev
- `push` to `staging` → deploys to staging  
- `push` to `production` → deploys to prod
- Manual trigger via Actions UI

## Configuration

See `.github/workflows/deploy-accounts-api.yml` for full configuration.

---

## Monitoring Workflow Runs

### View Workflow Status

1. Go to GitHub repository
2. Click **Actions** tab
3. View workflow runs and logs

### Failed Workflow

If a workflow fails:

1. Click on the failed workflow run
2. Expand the failed job/step
3. Review error logs
4. Fix the issue
5. Re-run the workflow

### Manual Trigger

To manually trigger a workflow:

1. Go to **Actions** tab
2. Select **Deploy Accounts API to EKS** workflow
3. Click **Run workflow**
4. Select branch and environment
5. Click **Run workflow** button

---

## Workflow Badges

Add a status badge to your README:

```markdown
![Deploy Status](https://github.com/<your-org>/<your-repo>/actions/workflows/deploy-accounts-api.yml/badge.svg)
```

---

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Actions for GitHub](https://github.com/aws-actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
