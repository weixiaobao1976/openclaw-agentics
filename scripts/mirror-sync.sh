#!/usr/bin/env bash
# mirror-sync.sh — 脑镜像双向同步脚本
# 
# 用法:
#   bash mirror-sync.sh auto    # 自动同步（本地→远程）
#   bash mirror-sync.sh pull    # 从远程拉取脑镜像
#   bash mirror-sync.sh status  # 检查同步状态

set -euo pipefail

WORKSPACE="${WORKSPACE:-$(dirname "$0")/..}"
cd "$WORKSPACE"

BRANCH="brain-backup"
REMOTE="origin"

log() { echo "✅ $1"; }
warn() { echo "⚠️ $1"; }
err() { echo "❌ $1"; }

case "${1:-auto}" in
  auto|push)
    log "检查认证..."
    if ! gh auth status &>/dev/null; then
      err "GitHub 认证失效，请运行: gh auth login -h github.com"
      exit 1
    fi

    log "确保 brain-backup 分支存在..."
    if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
      log "创建本地 branch: $BRANCH"
      git checkout -b "$BRANCH"
    else
      git checkout "$BRANCH"
    fi

    log "暂存当前分支的变更..."
    git stash push -m "pre-backup stash" 2>/dev/null || true

    log "添加脑文件..."
    git add -A

    if git diff --cached --quiet; then
      log "无变更，跳过 commit"
    else
      TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      git commit -m "brain mirror sync: $TS"
    fi

    log "推送到远程..."
    git push -u "$REMOTE" "$BRANCH" --force

    log "恢复之前暂存的变更..."
    git stash pop 2>/dev/null || true

    log "脑镜像同步完成 ✅"
    ;;

  pull)
    log "从远程拉取 brain-backup..."
    git fetch "$REMOTE" "$BRANCH" || {
      warn "远程无 brain-backup 分支，跳过"
      exit 0
    }

    log "合并到当前分支..."
    git checkout - && git merge "refs/remotes/$REMOTE/$BRANCH" --allow-unrelated-histories -m "merge brain backup" || true

    log "脑镜像拉取完成 ✅"
    ;;

  status)
    echo "=== 脑镜像同步状态 ==="
    echo "当前分支: $(git branch --show-current)"
    echo "brain-backup 分支: $(git branch --list "$BRANCH" | wc -l | xargs -I{} echo {})"
    echo "远程: $(git remote get-url "$REMOTE" 2>/dev/null || echo '无')"
    echo "认证: $(gh auth status 2>&1 | head -1)"
    echo "未提交变更: $(git status --short | wc -l | xargs -I{} echo {})"
    ;;

  *)
    echo "用法: bash mirror-sync.sh [auto|push|pull|status]"
    exit 1
    ;;
esac
