#!/usr/bin/env bash
# ============================================================================
# 🧬 小龙女分身 · 一键觉醒 v2
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/weixiaobao1976/openclaw-agentics/brain-backup/boot/bootstrap.sh | bash
#
# 分身体系:
#   从 GitHub 4 个仓库的 brain-backup 分支拉取全量状态文件
#   恢复到本地完整分身
#
# 恢复内容:
#   ✅ 行为规范  — TOOLS/MEMORY/AGENTS/SOUL/USER/IDENTITY/HEARTBEAT/TROUBLESHOOTING
#   ✅ 知识库     — 24 个生态项目分析
#   ✅ 技能文件   — 9 个 SKILL.md
#   ✅ 运维脚本   — backup-brain/self-learn/self-heal/weather/mirror-sync/crontab
#   ✅ 每日日志   — 6 份 memory 历史
#   ✅ 配置工具   — config-health-check.sh
#   ✅ 故障手册   — TROUBLESHOOTING.md
#   ✅ crontab    — 定时任务恢复
#   ✅ 完整性验证 — 每个文件校验
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

GH_USER="weixiaobao1976"
BRANCH="brain-backup"
BASE_URL="https://raw.githubusercontent.com/$GH_USER"

HOME_DIR="${HOME:-$HOME}"
OPENCLAW_DIR="$HOME_DIR/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace"
SCRIPTS_DIR="$OPENCLAW_DIR/scripts"
KNOWLEDGE_DIR="$WORKSPACE_DIR/knowledge"
MEMORY_DIR="$WORKSPACE_DIR/memory"
SKILLS_DIR="$WORKSPACE_DIR/skills"
CONFIG_DIR="$WORKSPACE_DIR/config"
BOOT_DIR="$WORKSPACE_DIR/boot"
LOG_DIR="$OPENCLAW_DIR/logs"
BACKUP_DIR="$OPENCLAW_DIR/backup/brain"

ERRORS=0
WARNINGS=0
RESTORED=0

# ============================================================
# 打印横幅
# ============================================================
banner() {
    echo ""
    echo -e "${CYAN}🧬 小龙女分身 · 一键觉醒${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  恢复源: ${GREEN}${GH_USER}/${BRANCH}${NC}"
    echo -e "  恢复至: ${CYAN}$WORKSPACE_DIR${NC}"
    echo ""
}

# ============================================================
# 下载单个文件
# ============================================================
download_file() {
    local repo="$1"
    local remote_path="$2"
    local local_path="$3"
    local label="${4:-$(basename "$local_path")}"

    local url="$BASE_URL/$repo/$BRANCH/$remote_path"
    mkdir -p "$(dirname "$local_path")"

    if curl -sSfL "$url" -o "$local_path" 2>/dev/null; then
        local size
        size=$(stat -c%s "$local_path" 2>/dev/null || echo 0)
        if [ "$size" -gt 0 ]; then
            echo -e "  ${GREEN}✅${NC} $label"
            RESTORED=$((RESTORED + 1))
            return 0
        fi
    fi

    echo -e "  ${RED}❌${NC} $label  — 下载失败"
    ERRORS=$((ERRORS + 1))
    return 1
}

# ============================================================
# 批量下载（带目录）
# ============================================================
download_dir() {
    local repo="$1"
    local remote_prefix="$2"
    local local_dir="$3"
    local total=0
    local success=0

    mkdir -p "$local_dir"

    # 通过 GitHub API 获取目录文件列表
    local api_url="https://api.github.com/repos/$GH_USER/$repo/git/trees/$BRANCH?recursive=1"
    local tree_data
    tree_data=$(curl -sSfL "$api_url" 2>/dev/null) || return 1

    # 提取匹配前缀的文件
    local files
    files=$(echo "$tree_data" | python3 -c "
import json, sys
data = json.load(sys.stdin)
prefix = '$remote_prefix/'
for item in data.get('tree', []):
    if item['type'] == 'blob' and item['path'].startswith(prefix):
        print(item['path'])
" 2>/dev/null) || return 1

    if [ -z "$files" ]; then
        return 0
    fi

    while IFS= read -r filepath; do
        if [ -z "$filepath" ]; then continue; fi
        
        # 去掉前缀，得到相对路径
        local rel_path="${filepath#$remote_prefix/}"
        local dest_file="$local_dir/$rel_path"
        local dest_dir
        dest_dir=$(dirname "$dest_file")
        
        mkdir -p "$dest_dir"
        total=$((total + 1))

        if curl -sSfL "$BASE_URL/$repo/$BRANCH/$filepath" -o "$dest_file" 2>/dev/null; then
            local size
            size=$(stat -c%s "$dest_file" 2>/dev/null || echo 0)
            if [ "$size" -gt 0 ]; then
                success=$((success + 1))
                RESTORED=$((RESTORED + 1))
            fi
        fi
    done <<< "$files"

    if [ "$success" -eq "$total" ]; then
        echo -e "  ${GREEN}✅${NC} $remote_prefix ($total 个文件)"
        return 0
    elif [ "$success" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️${NC} $remote_prefix ($success/$total 个文件)"
        ERRORS=$((ERRORS + (total - success)))
        return 1
    else
        echo -e "  ${RED}❌${NC} $remote_prefix (0/$total 个文件)"
        ERRORS=$((ERRORS + total))
        return 1
    fi
}

# ============================================================
# 安装 gh CLI
# ============================================================
install_gh() {
    if command -v gh &>/dev/null; then
        echo -e "  ${GREEN}✅${NC} gh CLI 已安装"
        return 0
    fi

    echo -e "  ${YELLOW}⬇️  安装 gh CLI...${NC}"
    
    if command -v apt &>/dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg 2>/dev/null | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null || true
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" 2>/dev/null | tee /etc/apt/sources.list.d/github-cli.list >/dev/null || true
        apt update 2>/dev/null && apt install -y gh 2>/dev/null || true
    elif command -v dnf &>/dev/null; then
        dnf install -y gh 2>/dev/null || true
    elif command -v pacman &>/dev/null; then
        pacman -S --noconfirm github-cli 2>/dev/null || true
    fi

    if command -v gh &>/dev/null; then
        echo -e "  ${GREEN}✅ gh CLI 安装成功${NC}"
        return 0
    else
        echo -e "  ${YELLOW}⚠️  gh CLI 未安装（可选，不影响恢复）${NC}"
        return 0
    fi
}

# ============================================================
# 恢复 crontab
# ============================================================
restore_crontab() {
    local cron_file="$SCRIPTS_DIR/crontab-reference.txt"
    if [ ! -f "$cron_file" ]; then
        echo -e "  ${YELLOW}⚠️  无 crontab 参考文件，跳过${NC}"
        return 0
    fi

    # 先备份当前 crontab
    crontab -l > /tmp/crontab-old-backup.txt 2>/dev/null || true

    # 安装 crontab 参考（只导入我们自己的任务，不动已有任务）
    local OPENCLAW_CRONS
    OPENCLAW_CRONS=$(grep -v "^#" "$cron_file" 2>/dev/null | grep -v "^$" || true)
    
    if [ -z "$OPENCLAW_CRONS" ]; then
        echo -e "  ${YELLOW}⚠️  crontab 参考文件为空，跳过${NC}"
        return 0
    fi

    # 合并：保留用户原有 + 加入 openclaw 任务（去重）
    (
        crontab -l 2>/dev/null || true
        echo "# 🧬 小龙女分身自动恢复 - $(date '+%Y-%m-%d %H:%M')"
        echo "$OPENCLAW_CRONS"
    ) | sort -u | crontab - 2>/dev/null && echo -e "  ${GREEN}✅${NC} crontab 已恢复" || echo -e "  ${YELLOW}⚠️${NC} crontab 恢复失败（可能需要手动设置）"
}

# ============================================================
# 完整性验证
# ============================================================
verify_integrity() {
    local manifest="$WORKSPACE_DIR/_manifest.json"
    if [ ! -f "$manifest" ]; then
        echo -e "  ${YELLOW}⚠️  无 manifest 文件，跳过完整性校验${NC}"
        return 0
    fi

    echo ""
    echo -e "  ${CYAN}🔍 文件完整性验证...${NC}"

    local errors=0

    while IFS='|' read -r name expected_size; do
        local actual_file=""
        
        case "$name" in
            configs/tools.md)            actual_file="$WORKSPACE_DIR/TOOLS.md" ;;
            configs/memory.md)           actual_file="$WORKSPACE_DIR/MEMORY.md" ;;
            configs/agents.md)           actual_file="$WORKSPACE_DIR/AGENTS.md" ;;
            configs/user.md)             actual_file="$WORKSPACE_DIR/USER.md" ;;
            configs/soul.md)             actual_file="$WORKSPACE_DIR/SOUL.md" ;;
            configs/identity.md)         actual_file="$WORKSPACE_DIR/IDENTITY.md" ;;
            configs/heartbeat.md)        actual_file="$WORKSPACE_DIR/HEARTBEAT.md" ;;
            configs/troubleshooting.md)  actual_file="$WORKSPACE_DIR/TROUBLESHOOTING.md" ;;
            skills/*.skill.md)           actual_file="$SKILLS_DIR/$(echo "$name" | sed 's|skills/||; s|\.skill\.md|/SKILL.md|')" ;;
            knowledge/*)                 actual_file="$KNOWLEDGE_DIR/$(echo "$name" | sed 's|knowledge/||')" ;;
            memory/*)                    actual_file="$MEMORY_DIR/$(echo "$name" | sed 's|memory/||')" ;;
            ops/*)                       actual_file="$SCRIPTS_DIR/$(echo "$name" | sed 's|ops/||')" ;;
            config/*)                    actual_file="$CONFIG_DIR/$(echo "$name" | sed 's|config/||')" ;;
            boot/*)                      actual_file="$BOOT_DIR/$(echo "$name" | sed 's|boot/||')" ;;
            *)                           echo -e "    ${YELLOW}⚠️  $name — 未知映射${NC}" ;;
        esac

        if [ -f "$actual_file" ]; then
            local actual_size
            actual_size=$(stat -c%s "$actual_file" 2>/dev/null || echo 0)
            if [ "$actual_size" -eq "$expected_size" ]; then
                :  # 不逐个打印，避免太吵
            else
                echo -e "    ${RED}❌${NC} $name  — 大小不匹配: 期望 ${expected_size}B, 实际 ${actual_size}B"
                errors=$((errors + 1))
            fi
        else
            echo -e "    ${RED}❌${NC} $name  — 文件不存在"
            errors=$((errors + 1))
        fi
    done < <(jq -r '.files[] | "\(.name)|\(.size)"' "$manifest" 2>/dev/null)

    if [ "$errors" -gt 0 ]; then
        echo -e "  ${RED}❌ $errors 个文件校验失败${NC}"
        ERRORS=$((ERRORS + errors))
        return 1
    else
        echo -e "  ${GREEN}✅ 全部文件完整性验证通过✓${NC}"
        return 0
    fi
}

# ============================================================
# 主流程
# ============================================================
main() {
    banner

    # 创建所有目录
    mkdir -p "$WORKSPACE_DIR" "$SCRIPTS_DIR" "$KNOWLEDGE_DIR" "$MEMORY_DIR"
    mkdir -p "$SKILLS_DIR" "$CONFIG_DIR" "$BOOT_DIR" "$LOG_DIR" "$BACKUP_DIR"
    
    echo -e "  ${CYAN}📥 阶段 1/5: 核心配置文件 (8 个)${NC}"
    AGENTICS="openclaw-agentics"
    download_file "$AGENTICS" "brain/configs/tools.md"          "$WORKSPACE_DIR/TOOLS.md"
    download_file "$AGENTICS" "brain/configs/memory.md"         "$WORKSPACE_DIR/MEMORY.md"
    download_file "$AGENTICS" "brain/configs/agents.md"         "$WORKSPACE_DIR/AGENTS.md"
    download_file "$AGENTICS" "brain/configs/user.md"           "$WORKSPACE_DIR/USER.md"
    download_file "$AGENTICS" "brain/configs/soul.md"           "$WORKSPACE_DIR/SOUL.md"
    download_file "$AGENTICS" "brain/configs/identity.md"       "$WORKSPACE_DIR/IDENTITY.md"
    download_file "$AGENTICS" "brain/configs/heartbeat.md"      "$WORKSPACE_DIR/HEARTBEAT.md"
    download_file "$AGENTICS" "brain/configs/troubleshooting.md" "$WORKSPACE_DIR/TROUBLESHOOTING.md"
    download_file "$AGENTICS" "brain/_manifest.json"            "$WORKSPACE_DIR/_manifest.json"
    echo ""

    echo -e "  ${CYAN}📥 阶段 2/5: 技能文件 (9 个)${NC}"
    mkdir -p "$SKILLS_DIR"/{capability-match,cli-anything-hub,gh-ops,github}
    mkdir -p "$SKILLS_DIR"/{gstack-openclaw-ceo-review,gstack-openclaw-investigate}
    mkdir -p "$SKILLS_DIR"/{gstack-openclaw-office-hours,gstack-openclaw-retro,mx-stocks-screener}
    download_file "$AGENTICS" "brain/skills/capability-match.skill.md"               "$SKILLS_DIR/capability-match/SKILL.md"
    download_file "$AGENTICS" "brain/skills/cli-anything-hub.skill.md"               "$SKILLS_DIR/cli-anything-hub/SKILL.md"
    download_file "$AGENTICS" "brain/skills/gh-ops.skill.md"                        "$SKILLS_DIR/gh-ops/SKILL.md"
    download_file "$AGENTICS" "brain/skills/github.skill.md"                        "$SKILLS_DIR/github/SKILL.md"
    download_file "$AGENTICS" "brain/skills/gstack-openclaw-ceo-review.skill.md"    "$SKILLS_DIR/gstack-openclaw-ceo-review/SKILL.md"
    download_file "$AGENTICS" "brain/skills/gstack-openclaw-investigate.skill.md"   "$SKILLS_DIR/gstack-openclaw-investigate/SKILL.md"
    download_file "$AGENTICS" "brain/skills/gstack-openclaw-office-hours.skill.md"  "$SKILLS_DIR/gstack-openclaw-office-hours/SKILL.md"
    download_file "$AGENTICS" "brain/skills/gstack-openclaw-retro.skill.md"         "$SKILLS_DIR/gstack-openclaw-retro/SKILL.md"
    download_file "$AGENTICS" "brain/skills/mx-stocks-screener.skill.md"            "$SKILLS_DIR/mx-stocks-screener/SKILL.md"
    echo ""

    echo -e "  ${CYAN}📥 阶段 3/5: 知识库 + 每日日志 (7 个)${NC}"
    TECH="openclaw-techniques"
    download_file "$TECH" "brain/knowledge/openclaw-ecosystem.md" "$KNOWLEDGE_DIR/openclaw-ecosystem.md"
    download_file "$TECH" "brain/memory/2026-04-14-model-identity.md" "$MEMORY_DIR/2026-04-14-model-identity.md"
    download_file "$TECH" "brain/memory/2026-04-15-1152.md"           "$MEMORY_DIR/2026-04-15-1152.md"
    download_file "$TECH" "brain/memory/2026-05-05.md"                "$MEMORY_DIR/2026-05-05.md"
    download_file "$TECH" "brain/memory/2026-05-09.md"                "$MEMORY_DIR/2026-05-09.md"
    download_file "$TECH" "brain/memory/2026-05-23.md"                "$MEMORY_DIR/2026-05-23.md"
    download_file "$TECH" "brain/memory/2026-05-24.md"                "$MEMORY_DIR/2026-05-24.md"
    echo ""

    echo -e "  ${CYAN}📥 阶段 4/5: 运维脚本 + 配置工具 (10 个)${NC}"
    TOOLS="openclaw-tools"
    download_file "$TOOLS" "brain/ops/backup-brain.mjs"            "$SCRIPTS_DIR/backup-brain.mjs"
    download_file "$TOOLS" "brain/ops/self-learn.mjs"              "$SCRIPTS_DIR/self-learn.mjs"
    download_file "$TOOLS" "brain/ops/self-heal-check.mjs"         "$SCRIPTS_DIR/self-heal-check.mjs"
    download_file "$TOOLS" "brain/ops/weather-forecast.js"         "$SCRIPTS_DIR/weather-forecast.js"
    download_file "$TOOLS" "brain/ops/gateway-check.sh"            "$SCRIPTS_DIR/gateway-check.sh"
    download_file "$TOOLS" "brain/ops/model-health-check.sh"       "$SCRIPTS_DIR/model-health-check.sh"
    download_file "$TOOLS" "brain/ops/mirror-sync.sh"              "$SCRIPTS_DIR/mirror-sync.sh"
    download_file "$TOOLS" "brain/ops/crontab-reference.txt"       "$SCRIPTS_DIR/crontab-reference.txt"
    download_file "$TOOLS" "brain/config/openclaw-config-health-check.sh" "$CONFIG_DIR/openclaw-config-health-check.sh"
    download_file "$AGENTICS" "brain/boot/bootstrap.sh"            "$BOOT_DIR/bootstrap.sh"
    echo ""

    echo -e "  ${CYAN}🔧 阶段 5/5: 后处理${NC}"
    # 设置执行权限
    chmod +x "$SCRIPTS_DIR"/*.mjs 2>/dev/null || true
    chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
    chmod +x "$SCRIPTS_DIR"/*.js 2>/dev/null || true
    chmod +x "$BOOT_DIR/bootstrap.sh" 2>/dev/null || true
    chmod +x "$CONFIG_DIR/openclaw-config-health-check.sh" 2>/dev/null || true
    echo -e "  ${GREEN}✅${NC} 执行权限已设置"

    # gh CLI
    install_gh

    # crontab 恢复
    restore_crontab

    # 完整性验证
    verify_integrity || true
    echo ""

    # ============================================================
    # 报告
    # ============================================================
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 更新 IDENTITY.md 时间戳
    if [ -f "$WORKSPACE_DIR/IDENTITY.md" ]; then
        local ts
        ts=$(date '+%Y-%m-%d %H:%M:%S')
        sed -i "s/TIMESTAMP_PLACEHOLDER/$ts/g" "$WORKSPACE_DIR/IDENTITY.md" 2>/dev/null || true
    fi

    if [ "$ERRORS" -gt 0 ]; then
        echo -e "  ${RED}⚠️  觉醒完成，但有 $ERRORS 个错误${NC}"
        echo -e "  ${YELLOW}建议检查网络连接后重新运行${NC}"
    else
        echo -e "  ${GREEN}🧬 小龙女分身觉醒成功！${NC}"
        echo ""
        echo -e "  恢复统计: ${CYAN}$RESTORED 个文件${NC}"
        echo ""
        echo -e "  📄 行为规范:    ${CYAN}TOOLS.md / MEMORY.md / AGENTS.md / SOUL.md / USER.md${NC}"
        echo -e "  📚 知识库:      ${CYAN}$KNOWLEDGE_DIR/${NC}"
        echo -e "  🔧 技能:       ${CYAN}$SKILLS_DIR/${NC} (9 个)"
        echo -e "  📜 运维脚本:    ${CYAN}$SCRIPTS_DIR/${NC}"
        echo -e "  📝 每日日志:    ${CYAN}$MEMORY_DIR/${NC}"
        echo -e "  🛠️  配置工具:   ${CYAN}$CONFIG_DIR/${NC}"
        echo -e "  🐉 故障手册:   ${CYAN}$WORKSPACE_DIR/TROUBLESHOOTING.md${NC}"
        echo ""
        echo -e "  ${YELLOW}💡 建议下一步:${NC}"
        echo -e "    1. 检查 OpenClaw 版本:   ${CYAN}openclaw --version${NC}"
        echo -e "    2. 配置健康检查:         ${CYAN}bash $CONFIG_DIR/openclaw-config-health-check.sh${NC}"
        echo -e "    3. 配置 GitHub SSH 密钥: ${CYAN}gh auth login${NC}"
        echo -e "    4. 跑一次学习循环:       ${CYAN}node $SCRIPTS_DIR/self-learn.mjs${NC}"
        echo -e "    5. 同步到 GitHub:        ${CYAN}bash $SCRIPTS_DIR/mirror-sync.sh${NC}"
    fi

    echo ""
    exit $ERRORS
}

main "$@"