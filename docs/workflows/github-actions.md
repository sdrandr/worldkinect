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

[Add more GitHub Actions details]
