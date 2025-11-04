# Documentation Instructions

## Filling in the Documentation

The documentation structure has been created with placeholder files. Now you need to copy the content from the Claude artifacts into each file.

### Files to Update

1. **docs/guides/01-iam-setup.md**
   - Copy from artifact: "IAM Setup Guide - README"

2. **docs/guides/02-two-account-setup.md**
   - Copy from artifact: "Two-Account Setup Guide"

3. **docs/guides/03-eks-migration.md**
   - Copy from artifact: "EKS Migration Guide"

4. **docs/guides/05-cicd-automation.md**
   - Copy from artifact: "CI/CD Automation - README"

5. **docs/guides/learning-roadmap.md**
   - Copy from artifact: "WorldKinect Tech Stack Learning Roadmap"

### How to Copy Content

1. Find the artifact in your conversation with Claude
2. Copy all the markdown content
3. Open the corresponding file in your editor
4. Replace the `[Content to be added]` section with the copied content
5. Save the file

### Updating Documentation

When you need to update the docs:

```bash
# Edit the relevant file
vim docs/guides/01-iam-setup.md

# Commit the changes
git add docs/
git commit -m "docs: Update IAM setup guide"
git push origin main
```

### Viewing Documentation

```bash
# View on GitHub
# Navigate to: https://github.com/<your-org>/<your-repo>/tree/main/docs

# Or view locally
# Open docs/README.md in your editor or browser
```

### Optional: Set up MkDocs

If you want a beautiful documentation website:

```bash
pip install mkdocs-material
mkdocs new .
# Edit mkdocs.yml to match docs structure
mkdocs serve
# Visit http://localhost:8000
```

---

Happy documenting! 📚
