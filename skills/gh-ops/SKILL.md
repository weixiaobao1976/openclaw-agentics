---
name: gh-ops
description: "Full-stack GitHub ops via `gh` CLI: repos, issues, PRs, CI, releases, secrets, org management."
allowed-tools: [exec]
---

# gh-ops — GitHub 全操作技能

基于 `gh` CLI，管理 GitHub 资源。使用 `ghp_` 经典 token。

## 快速操作

```bash
# 仓库
gh repo create repo-name --public
gh repo view owner/repo --json name,visibility
gh repo delete owner/repo --yes

# Issue
gh issue list --repo owner/repo --limit 20
gh issue create --repo owner/repo --title "..." --body "..."

# PR
gh pr list --repo owner/repo --state open
gh pr create --repo owner/repo --base main --head feature
gh pr merge 55 --repo owner/repo --squash --delete-branch

# CI
gh run list --repo owner/repo --limit 10
gh run view <run-id> --repo owner/repo --log-failed

# Secrets
gh secret list --repo owner/repo
gh secret set MY_KEY --repo owner/repo --body "$VALUE"
```
