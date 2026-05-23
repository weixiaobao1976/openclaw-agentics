---
name: gh-ops
description: "Full-stack GitHub ops via `gh` CLI: repos, issues, PRs, CI, releases, secrets, org management."
openclaw:
  emoji: "🐙"
  requires: { bins: ["gh"] }
---

# gh-ops

基于 `gh` CLI 的 GitHub 全操作。`ghp_` 经典 token。

## GitHub Token

当前使用 `ghp_` 经典 token，高权限（repo/workflow/delete_repo/admin:org）。

```bash
gh auth status                        # 验证 token
gh auth token | cut -c1-4            # 查看前缀 (ghp_)
```

## PR

```bash
gh pr list --repo owner/repo --json number,title,state,author,url
gh pr view 55 --repo owner/repo
gh pr view https://github.com/owner/repo/pull/55   # URL 直接使用
gh pr checks 55 --repo owner/repo
gh pr create --repo owner/repo --base main --head feature
gh pr merge 55 --repo owner/repo --squash --delete-branch
```

## Issue

```bash
gh issue list --repo owner/repo --state open
gh issue view 42 --repo owner/repo --json title,body,comments,labels
gh issue create --repo owner/repo --title "Bug: ..." --body-file /tmp/issue.md
gh issue close 42 --repo owner/repo --comment "Fixed"
```

## CI (Actions)

```bash
gh run list --repo owner/repo --limit 10
gh run view <run-id> --repo owner/repo --log-failed   # 只看失败日志
gh run rerun <run-id> --repo owner/repo --failed       # 仅重跑失败 job
```

## API 高级查询

```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
gh api --cache 1h repos/owner/repo                     # 1h 缓存
```

## 仓库管理

```bash
gh repo create repo-name --public --description "..."
gh repo delete owner/repo --yes
gh repo edit owner/repo --add-topic ai,agent
```

## 实用脚本

```bash
node ~/.openclaw/workspace/skills/gh-ops/scripts/list-runs.mjs owner/repo --days 7 --limit 20
node ~/.openclaw/workspace/skills/gh-ops/scripts/changelog.mjs owner/repo --from v1.0.0
```
