---
name: gh-ops
description: "Full-stack GitHub ops via `gh` CLI: repos, issues, PRs, CI, releases, secrets, org management. Uses `ghp_` classic token."
allowed-tools: [exec]
---

# gh-ops — GitHub 全操作技能

基于 `gh` CLI，管理 GitHub 资源。本地已配高权限 `ghp_` token。

## 前置

所有操作走 `gh` CLI（已验证 token，已配 git credential helper）。

## 仓库管理

```bash
# 创建
gh repo create repo-name --public --description "..."
gh repo create repo-name --private --clone

# 查看/列表
gh repo view owner/repo --json name,description,visibility,defaultBranch
gh repo list owner --limit 20 --json name,visibility,updatedAt

# 设置
gh repo edit owner/repo --description "..." --homepage "..." --default-branch main
gh repo edit owner/repo --add-topic ai,agent,tool --visibility private

# 删除
gh repo delete owner/repo --yes

# Fork/Sync
gh repo fork owner/repo --clone
gh repo sync owner/repo
```

## Issue 管理

```bash
# 列表
gh issue list --repo owner/repo --limit 20 --state open --json number,title,labels,assignees --jq '.[] | "##\(.number): \(.title)"'

# 查看
gh issue view 42 --repo owner/repo

# 创建
gh issue create --repo owner/repo --title "..." --body "..." --label bug --assignee @me

# 关闭/重开
gh issue close 42 --repo owner/repo
gh issue reopen 42 --repo owner/repo

# 批量操作（通过 API 扩展）
gh api repos/owner/repo/issues --method POST -f title="..." -f body="..." -f labels='["bug"]'
```

## PR 管理

```bash
# 列表
gh pr list --repo owner/repo --state open --json number,title,headRefName,author

# 查看
gh pr view 55 --repo owner/repo

# 创建
gh pr create --repo owner/repo --base main --head feature --title "..." --body "..."

# 状态检查
gh pr checks 55 --repo owner/repo
gh pr review 55 --repo owner/repo --request-reviewer @me
gh pr merge 55 --repo owner/repo --squash --delete-branch
```

## CI/CD (Actions)

```bash
# 列出 workflow run（见 scripts/list-runs.mjs）
# 手动触发
gh workflow run build.yml --repo owner/repo --ref main -f param=value

# 查看运行日志
gh run view <run-id> --repo owner/repo
gh run view <run-id> --repo owner/repo --log-failed

# 下载 artifact
gh run download <run-id> --repo owner/repo --dir ./artifacts

# 取消/重跑
gh run cancel <run-id> --repo owner/repo
gh run rerun <run-id> --repo owner/repo
```

## Secrets & Variables

```bash
# 列出
gh secret list --repo owner/repo
gh variable list --repo owner/repo

# 设置
gh secret set MY_KEY --repo owner/repo --body "$VALUE"
gh variable set MY_VAR --repo owner/repo --body "$VALUE"

# 删除
gh secret remove MY_KEY --repo owner/repo
gh variable remove MY_VAR --repo owner/repo
```

## Release

```bash
# 创建
gh release create v1.0.0 --repo owner/repo --title "v1.0.0" --notes "Release notes..."
gh release create v1.0.0 --repo owner/repo --generate-notes

# 上传文件
gh release upload v1.0.0 ./dist/*.zip --repo owner/repo

# 列表
gh release list --repo owner/repo --limit 10

# 下载
gh release download v1.0.0 --repo owner/repo --dir ./release
```

## Search

```bash
# 仓库（详见 github-search skill）
gh search repos "topic:agent language:python" --limit 20 --json fullName,stars

# Issue
gh search issues "label:bug state:open" --repo owner/repo

# 代码
gh search code "function_name" --repo owner/repo
```

## 组织管理

```bash
# 团队列表
gh org list teams org-name
gh api orgs/org-name/teams --jq '.[].name'

# 成员
gh api orgs/org-name/members --jq '.[].login'
```

## 实用脚本

```bash
# 工作流报告
node ~/.openclaw/workspace/skills/gh-ops/scripts/list-runs.mjs owner/repo --days 7 --limit 20

# 自动 CHANGELOG
node ~/.openclaw/workspace/skills/gh-ops/scripts/changelog.mjs owner/repo --from v1.0.0 --to v1.1.0
```

## 注意事项

- 用 `--repo owner/repo` 指定仓库，否则用当前目录 git 仓库
- `gh api` 可执行 REST API 未封装的任何操作
- `--json` 指定字段，`--jq` 做 jq 过滤
- 删除操作不可逆，确认后再执行