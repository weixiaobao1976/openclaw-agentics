#!/usr/bin/env bash
# ================================================================
# OpenClaw 全能管理脚本
# Ubuntu/Linux - 备份·恢复·一键故障排除·重启
# 参考: https://docs.openclaw.ai/gateway/troubleshooting
# ================================================================
# 使用: chmod +x openclaw-restore.sh && ./openclaw-restore.sh
# ================================================================

# ---- 颜色 -----------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

# ---- 路径 -----------------------------------------------------
OC_DIR="$HOME/.openclaw"
CONFIG="$OC_DIR/openclaw.json"
NOW=$(date +%Y%m%d-%H%M%S)

# ---- 辅助函数 -------------------------------------------------
info()  { echo -e "${CYAN}..${NC} $*"; }
ok()    { echo -e "${GREEN}OK${NC} $*"; }
warn()  { echo -e "${YELLOW}!!${NC} $*"; }
err()   { echo -e "${RED}XX${NC} $*"; }
header(){ echo -e "\n${BOLD}--- $* ---${NC}\n"; }
pause() { echo; read -p "按回车返回..."; }
section() { echo -e "\n${BOLD}${BLUE}>>> $*${NC}"; }

# ================================================================
# 一键故障排除
# ================================================================

troubleshoot() {
    header "一键故障排除"
    echo "正在执行官方诊断梯级（status -> doctor -> logs）..."
    echo

    section "1. 系统与版本信息"
    echo "  系统启动: $(who -b 2>/dev/null | cut -d' ' -f3- || echo '?')"
    echo "  当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
    command -v openclaw &>/dev/null && echo "  OpenClaw: $(openclaw --version 2>&1)" || warn "openclaw 命令未找到"
    echo "  配置文件: $(basename $CONFIG) ($(stat --format='%s' $CONFIG 2>/dev/null || echo '?') 字节)"
    echo "  服务文件: /etc/systemd/system/openclaw-gateway.service"
    echo

    section "2. Gateway 状态诊断"
    echo "  systemctl enabled: $(systemctl is-enabled openclaw-gateway.service 2>/dev/null || echo '未知')"
    if gateway_real_status; then
        ok "Gateway 服务运行中"
        local svc_status="active"
    else
        local svc_status=$(systemctl is-active openclaw-gateway.service 2>/dev/null || echo 'unknown')
        warn "Gateway 服务状态: $svc_status"
    fi

    local port=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('gateway',{}).get('port',18789))" 2>/dev/null || echo "18789")
    echo "  Gateway 端口: $port"
    if ss -tlnp "sport = :$port" 2>/dev/null | grep -q "openclaw\|node"; then
        ok "端口 $port 已被 OpenClaw 占用"
    elif ss -tlnp "sport = :$port" 2>/dev/null | grep -q .; then
        warn "端口 $port 被其他进程占用:"
        ss -tlnp "sport = :$port" 2>/dev/null | head -3
    else
        warn "端口 $port 未被占用"
    fi

    local gw_pid=$(pgrep -f "openclaw.*gateway" 2>/dev/null | head -1)
    if [[ -n "$gw_pid" ]]; then
        local gw_etime=$(ps -o etime -p "$gw_pid" 2>/dev/null | tail -1 | tr -d ' ')
        ok "Gateway 进程 PID=$gw_pid 已运行 $gw_etime"
    else
        warn "未找到 Gateway 进程"
    fi
    echo

    section "3. openclaw status"
    command -v openclaw &>/dev/null && openclaw status 2>&1 || warn "openclaw 不可用"
    echo

    section "4. openclaw gateway status"
    command -v openclaw &>/dev/null && openclaw gateway status 2>&1 || warn "openclaw 不可用"
    echo

    section "5. openclaw doctor"
    command -v openclaw &>/dev/null && openclaw doctor 2>&1 || warn "openclaw 不可用"
    echo

    section "6. 配置健康检查"
    if [[ -f "$CONFIG" ]]; then
        python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null \
            && ok "配置文件 JSON 格式正确" \
            || err "配置文件 JSON 格式无效！建议使用 [3] 选择备份并恢复"
    else
        err "配置文件不存在！"
    fi

    section "7. 版本一致性检查"
    if command -v openclaw &>/dev/null && [[ -f "$CONFIG" ]]; then
        local binary_ver=$(openclaw --version 2>&1 | grep -oP '[\d]+\.[\d]+\.[\d]+' | head -1)
        local config_ver=$(python3 -c "
import json
c = json.load(open('$CONFIG'))
print(c.get('meta',{}).get('lastTouchedVersion','unknown'))
" 2>/dev/null)
        if [[ "$config_ver" == "unknown" ]]; then
            info "配置文件未记录版本号（旧版格式）"
        elif [[ "$binary_ver" == "$config_ver"* ]]; then
            ok "二进制版本 ($binary_ver) 与配置版本 ($config_ver) 一致"
        else
            warn "二进制版本 ($binary_ver) 与配置版本 ($config_ver) 不一致，建议运行 doctor --fix"
        fi
    fi
    echo

    section "8. 最近 15 条 Gateway 日志"
    if journalctl -u openclaw-gateway.service --no-pager -n 15 --no-hostname 2>/dev/null | grep -q .; then
        journalctl -u openclaw-gateway.service --no-pager -n 15 --no-hostname 2>/dev/null | while IFS= read -r line; do
            if echo "$line" | grep -qi "error\|fail\|fatal\|warn\|refusing\|blocked\|EADDRINUSE"; then
                echo -e "  ${RED}$line${NC}"
            elif echo "$line" | grep -qi "ready\|started\|listening\|ok\|success"; then
                echo -e "  ${GREEN}$line${NC}"
            else
                echo "  $line"
            fi
        done
    else
        info "暂无日志"
    fi

    echo
    section "诊断总结"
    local issues=0
    [[ "$svc_status" != "active" ]] && ((issues++))
    ! ss -tlnp "sport = :$port" 2>/dev/null | grep -q "openclaw\|node" && ((issues++))
    [[ -z "$gw_pid" ]] && ((issues++))
    [[ ! -f "$CONFIG" ]] && ((issues++))

    if [[ $issues -eq 0 ]]; then
        ok "未发现明显问题，系统运行正常"
    else
        warn "发现 $issues 个潜在问题"
        echo "  建议操作:"
        echo "    [A] openclaw doctor --fix  自动修复"
        echo "    [B] openclaw gateway restart   重启 Gateway"
        [[ "$svc_status" != "active" ]] && echo "    [C] sudo systemctl start openclaw-gateway.service  启动服务"
        echo "    [D] 打开官方文档: https://docs.openclaw.ai/gateway/troubleshooting"
        echo
        read -p "是否立即运行 doctor --fix 自动修复？(y/N): " fix_choice
        case "${fix_choice,,}" in
            y|yes)
                section "运行 doctor --fix"
                openclaw doctor --fix 2>&1 || warn "自动修复未完全成功"
                ok "自动修复完成"
                read -p "是否重启 Gateway？(y/N): " restart_after_fix
                case "${restart_after_fix,,}" in y|yes) openclaw gateway restart 2>&1 || sudo systemctl restart openclaw-gateway.service ;; esac
                ;;
        esac
    fi
    echo
    info "故障排除完成。详细手册: https://docs.openclaw.ai/gateway/troubleshooting"
}

# ---- 快速健康检查小红点 -------------------------------------------
gateway_real_status() {
    if systemctl is-active openclaw-gateway.service &>/dev/null; then
        return 0
    fi
    local gw_port=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('gateway',{}).get('port',18789))" 2>/dev/null || echo "18789")
    if pgrep -f "openclaw.*gateway" &>/dev/null && ss -tlnp "sport = :$gw_port" 2>/dev/null | grep -q "node"; then
        return 0
    fi
    return 1
}

quick_health_check() {
    local issues=0 hints=""
    if ! gateway_real_status; then
        ((issues++)); hints="${hints}  Gateway 未运行"
    fi
    if [[ -f "$CONFIG" ]]; then
        ! python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null && ((issues++)) && hints="${hints}  配置损坏"
    else
        ((issues++)) && hints="${hints}  配置缺失"
    fi
    [[ $issues -gt 0 ]] && echo -e "  ${RED}!! 发现 $issues 个问题:${hints}${NC}"
}

# ================================================================
# 备份功能
# ================================================================

# ---- 备份模式选择菜单 -------------------------------------------
backup_menu() {
    while true; do
        header "备份模式选择"
        echo "  ${BOLD}A)${NC} 安全备份（停止 Gateway）— 推荐"
        echo "     先停止 Gateway，确保备份期间配置静止"
        echo "     备份完整一致，但会有约 5-10 秒停机"
        echo
        echo "  ${BOLD}B)${NC} 热备份（不停止 Gateway）"
        echo "     Gateway 保持运行，备份期间配置可能"
        echo "     被实时修改，备份可能不完全一致"
        echo
        echo "  ${BOLD}C)${NC} 仅备份配置文件（不打包，推荐日常）"
        echo "     仅备份 openclaw.json + credentials/"
        echo "     快速、无停机、占用小、Gateway 不中断"
        echo
        echo "  ${BOLD}0)${NC} 返回主菜单"
        echo
        read -p "请选择备份模式 (A/B/C/0): " mode
        mode="${mode,,}"
        case "$mode" in
            a)  backup_mode_a; return $? ;;
            b)  backup_mode_b; return $? ;;
            c)  backup_mode_c; return $? ;;
            0)  info "返回主菜单"; return 0 ;;
            *)  warn "请输入 A、B、C 或 0"; sleep 1 ;;
        esac
    done
}

# ---- A) 安全备份（停止 Gateway）----------------------------------
backup_mode_a() {
    info "准备安全备份..."
    local was_running=false
    if gateway_real_status; then
        was_running=true
        warn "正在停止 Gateway..."
        command -v openclaw &>/dev/null && openclaw gateway stop 2>&1 || true
        sleep 3
        if gateway_real_status; then
            warn "Gateway 未完全停止，尝试 systemctl stop"
            sudo systemctl stop openclaw-gateway.service 2>/dev/null || true
            sleep 2
        fi
        ok "Gateway 已停止"
    fi

    header "执行安全备份"
    local dest_dir="$OC_DIR/backup-full-$NOW"
    mkdir -p "$dest_dir"

    cp "$CONFIG" "$dest_dir/" 2>/dev/null && ok "  openclaw.json" || warn "  openclaw.json (无)"
    cp "$OC_DIR/gateway-owner.json" "$dest_dir/" 2>/dev/null && ok "  gateway-owner.json" || warn "  gateway-owner.json (无)"
    cp -r "$OC_DIR/credentials" "$dest_dir/" 2>/dev/null && ok "  credentials/" || warn "  credentials/ (无)"
    cp "$OC_DIR/clawpanel-device-key.json" "$dest_dir/" 2>/dev/null && ok "  clawpanel-device-key.json" || warn "  clawpanel-device-key.json (无)"
    cp "$OC_DIR/update-check.json" "$dest_dir/" 2>/dev/null && ok "  update-check.json" || warn "  update-check.json (无)"
    cp "$OC_DIR/version-history.json" "$dest_dir/" 2>/dev/null && ok "  version-history.json" || warn "  version-history.json (无)"

    local archive="$OC_DIR/backup-full-$NOW.tar.gz"
    tar -czf "$archive" -C "$OC_DIR" "backup-full-$NOW" 2>/dev/null
    local asize=$(stat --format='%s' "$archive" 2>/dev/null | numfmt --to=iec --format='%.1f' 2>/dev/null || stat --format='%s' "$archive" 2>/dev/null || echo "?")
    ok "打包完成: $(basename $archive) (${asize}B)"

    # 兼容单文件备份
    cp "$CONFIG" "$OC_DIR/openclaw.json.manual-backup-$NOW" 2>/dev/null || true

    # 恢复 Gateway
    if $was_running; then
        info "正在恢复 Gateway 运行..."
        command -v openclaw &>/dev/null && openclaw gateway start 2>&1 || true
        sleep 2
        if gateway_real_status; then
            ok "Gateway 已恢复运行"
        else
            warn "Gateway 未自动恢复，稍后手动启动："
            echo "    sudo systemctl start openclaw-gateway.service"
        fi
    fi

    echo
    ok "安全备份完成！"
    echo "  完整打包: $archive"
    echo "  原始目录: $dest_dir/"
    return 0
}

# ---- B) 热备份（不停止 Gateway）----------------------------------
backup_mode_b() {
    header "执行热备份"
    info "Gateway 保持运行，配置实时备份..."

    local dest_dir="$OC_DIR/backup-hot-$NOW"
    mkdir -p "$dest_dir"

    cp "$CONFIG" "$dest_dir/" 2>/dev/null && ok "  openclaw.json" || warn "  openclaw.json (无)"
    cp "$OC_DIR/gateway-owner.json" "$dest_dir/" 2>/dev/null && ok "  gateway-owner.json" || warn "  gateway-owner.json (无)"
    cp -r "$OC_DIR/credentials" "$dest_dir/" 2>/dev/null && ok "  credentials/" || warn "  credentials/ (无)"
    cp "$OC_DIR/clawpanel-device-key.json" "$dest_dir/" 2>/dev/null && ok "  clawpanel-device-key.json" || warn "  clawpanel-device-key.json (无)"
    cp "$OC_DIR/update-check.json" "$dest_dir/" 2>/dev/null && ok "  update-check.json" || warn "  update-check.json (无)"
    cp "$OC_DIR/version-history.json" "$dest_dir/" 2>/dev/null && ok "  version-history.json" || warn "  version-history.json (无)"

    cp "$CONFIG" "$OC_DIR/openclaw.json.manual-backup-$NOW" 2>/dev/null || true

    echo
    ok "热备份完成！"
    echo "  备份路径: $dest_dir/"
    echo "  (如需完整一致的安全备份，下次请选 A)"
    return 0
}

# ---- C) 仅备份配置文件（推荐日常）--------------------------------
backup_mode_c() {
    header "执行日常配置备份"
    info "Gateway 不中断，仅备份关键配置文件..."

    local dest="$OC_DIR/openclaw.json.manual-backup-$NOW"
    if cp "$CONFIG" "$dest"; then
        chmod 600 "$dest"
        local dsize=$(stat --format='%s' "$dest" 2>/dev/null | numfmt --to=iec --format='%.1f' 2>/dev/null || stat --format='%s' "$dest" 2>/dev/null || echo "?")
        ok "openclaw.json -> $(basename $dest) (${dsize}B)"
    else
        err "openclaw.json 备份失败！"
    fi

    if [[ -d "$OC_DIR/credentials" ]]; then
        local cred_dest="$OC_DIR/credentials-backup-$NOW"
        cp -r "$OC_DIR/credentials" "$cred_dest" 2>/dev/null
        ok "credentials/ -> $(basename $cred_dest)"
    fi

    echo
    ok "日常备份完成，Gateway 运行正常"
    return 0
}

# ================================================================
# 备份列表 / 恢复 / 重启 / 摘要
# ================================================================

list_backups() {
    local tmpfile=$(mktemp /tmp/oc_backups.XXXXXX)
    find "$OC_DIR" -maxdepth 1 -name 'openclaw.json.*' ! -name '*clobbered*' \
        -printf '%T@\t%p\n' 2>/dev/null | sort -rn -t$'\t' -k1 > "$tmpfile"

    if [[ ! -s "$tmpfile" ]]; then
        warn "未找到任何备份文件！"
        rm -f "$tmpfile"
        return 1
    fi

    echo
    printf "  %-4s %-22s %-10s %-8s %s\n" "序号" "备份时间" "大小" "有效" "文件名"
    printf "  %s\n" "----------------------------------------"

    local i=0; BACKUP_FILES=()
    while IFS= read -r line; do
        local f=$(echo "$line" | cut -f2-)
        ((i++))
        local name=$(basename "$f")
        local size=$(stat --format='%s' "$f" 2>/dev/null || echo "0")
        local size_hr=$(numfmt --to=iec --format='%.1f' "$size" 2>/dev/null || echo "${size}B")
        local mtime=$(stat --format='%y' "$f" 2>/dev/null | cut -d. -f1)
        local valid="?"
        python3 -c "import json; json.load(open('$f'))" 2>/dev/null && valid="OK" || valid="NO"
        printf "  %-4d %-22s %-10s %-8s %s\n" "$i" "$mtime" "$size_hr" "$valid" "$name"
        BACKUP_FILES+=("$f")
    done < "$tmpfile"
    rm -f "$tmpfile"
    echo
    ok "共 ${#BACKUP_FILES[@]} 个备份文件"
    return 0
}

select_backup() {
    [[ ${#BACKUP_FILES[@]} -eq 0 ]] && { err "没有可选的备份文件"; return 1; }
    while true; do
        echo
        read -p "请输入要恢复的备份序号 (0=返回): " choice
        choice="${choice// /}"
        [[ "$choice" == "0" ]] && { echo; info "返回"; return 1; }
        ! [[ "$choice" =~ ^[0-9]+$ ]] && { warn "请输入有效数字"; continue; }
        local idx=$((choice - 1))
        if [[ $idx -ge 0 && $idx -lt ${#BACKUP_FILES[@]} ]]; then
            SELECTED="${BACKUP_FILES[$idx]}"
            ok "已选择: $(basename $SELECTED)"
            return 0
        else
            warn "序号超出范围 (1-${#BACKUP_FILES[@]})"
        fi
    done
}

do_restore() {
    local src="$1"
    header "恢复确认"
    echo "  来源: $(basename $src)"
    local fsize=$(stat --format='%s' "$src" 2>/dev/null || echo "?")
    local fdate=$(stat --format='%y' "$src" 2>/dev/null | cut -d. -f1)
    echo "  大小: $fsize 字节"
    echo "  时间: $fdate"
    echo
    read -p "确定恢复此备份？(y/N) " confirm
    case "$confirm" in [yY]|[yY][eE][sS]) ;; *) info "已取消"; return 1 ;; esac
    # 先备份当前配置（C模式，最轻量不中断）
    backup_mode_c > /dev/null 2>&1 || true
    if cp "$src" "$CONFIG"; then
        chmod 600 "$CONFIG"
        ok "配置恢复成功！"
        return 0
    else
        err "配置恢复失败！"
        return 1
    fi
}

validate_restore() {
    header "配置验证"
    [[ ! -f "$CONFIG" ]] && { err "配置文件不存在！"; return 1; }
    if python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
        ok "JSON 格式验证通过"
        python3 -c "import json; c=json.load(open('$CONFIG')); print('  agents 段:', 'OK' if 'agents' in c else 'WARNING 缺失'); print('  大小:', len(json.dumps(c)), '字节')" 2>/dev/null || true
        return 0
    else
        err "JSON 无效！"
        return 1
    fi
}

restart_gateway() {
    header "重启 Gateway"
    echo "是否立即重启 Gateway？"
    echo "  1) 重启 Gateway"
    echo "  0) 稍后手动重启"
    echo
    read -p "请选择 (1/0): " rchoice
    case "${rchoice// /}" in
        1)
            info "正在重启 Gateway..."
            if openclaw gateway restart 2>/dev/null; then
                ok "Gateway 重启成功!"
                sleep 1
                gateway_real_status && ok "Gateway 运行中" || warn "请稍后检查: systemctl status openclaw-gateway.service"
            else
                warn "自动重启失败，手动执行: sudo systemctl restart openclaw-gateway.service"
            fi
            ;;
        *)  info "稍后手动重启: sudo systemctl restart openclaw-gateway.service" ;;
    esac
}

show_summary() {
    header "当前配置摘要"
    [[ ! -f "$CONFIG" ]] && { warn "配置文件不存在"; return; }
    python3 -c "
import json
c = json.load(open('$CONFIG'))
agents = c.get('agents', {}).get('defaults', {})
model = agents.get('model', {})
print(f'  代理主模型: {model.get(\"primary\", \"未设置\")}')
fb = model.get('fallbacks', [])
if fb: print(f'  备用模型: {\", \".join(fb)}')
binds = [b.get('match',{}).get('channel','?') for b in c.get('bindings',[])]
print(f'  绑定平台: {\", \".join(binds) if binds else \"无\"}')
plugins = c.get('plugins',{}).get('entries',{})
enabled = [k for k,v in plugins.items() if v.get('enabled')]
print(f'  已启用插件: {\", \".join(enabled) if enabled else \"无\"}')
mcp = c.get('mcp',{}).get('servers',{})
if mcp: print(f'  MCP 服务: {\", \".join(mcp.keys())}')
print(f'  配置大小: {len(json.dumps(c))} 字节')
" 2>/dev/null || echo "  无法解析"
}

# ================================================================
# 主菜单
# ================================================================

main_menu() {
    while true; do
        clear
        echo -e "${BOLD}${CYAN}"
        echo "============================================"
        echo "    OpenClaw 全能管理工具"
        echo "    $(date '+%Y-%m-%d %H:%M')"
        echo "============================================"
        echo -e "${NC}"
        local fsize="?"
        [[ -f "$CONFIG" ]] && fsize=$(stat --format='%s' "$CONFIG" 2>/dev/null | numfmt --to=iec --format='%.1f' 2>/dev/null || echo "?")
        echo "  配置文件: $(basename $CONFIG) ($fsize)"
        if gateway_real_status; then
            echo -e "  Gateway:   ${GREEN}运行中${NC}"
        else
            echo -e "  Gateway:   ${RED}未运行${NC}"
        fi
        quick_health_check
        echo
        echo "  [1] 备份当前配置 (选择模式)"
        echo "  [2] 查看备份列表"
        echo "  [3] 选择备份并恢复"
        echo "  [4] 重启 Gateway"
        echo "  [5] 查看配置摘要"
        echo "  [6] 一键故障排除"
        echo "  [7] 快速修复 (doctor --fix)"
        echo "  [0] 退出"
        echo
        read -p "请选择 (0-7): " choice
        choice="${choice// /}"
        case "$choice" in
            1) backup_menu; pause ;;
            2) header "历史备份列表"; list_backups || true; pause ;;
            3)
                header "选择备份恢复"
                if list_backups; then
                    if select_backup; then
                        echo
                        if do_restore "$SELECTED"; then
                            validate_restore
                            echo
                            restart_gateway
                        fi
                    fi
                fi
                pause ;;
            4) restart_gateway; pause ;;
            5) show_summary; pause ;;
            6) troubleshoot; pause ;;
            7)
                header "快速修复 (doctor --fix)"
                command -v openclaw &>/dev/null && openclaw doctor --fix 2>&1 || err "openclaw 不可用"
                echo
                read -p "修复完成，是否重启 Gateway？(y/N): " fr
                case "${fr,,}" in y|yes) openclaw gateway restart 2>&1 || sudo systemctl restart openclaw-gateway.service ;; esac
                pause ;;
            0) header "退出"; ok "感谢使用！"; exit 0 ;;
            *) warn "无效选项"; sleep 1 ;;
        esac
    done
}

# ================================================================
# 入口
# ================================================================

if [[ $# -ge 1 ]]; then
    case "$1" in
        backup) backup_menu ;;
        list)   list_backups ;;
        doctor|fix|repair) troubleshoot ;;
        help|--help|-h)
            echo "用法: $0 [backup|list|doctor|fix|repair]"
            echo "  直接运行 -> 交互式菜单"
            echo "  backup   -> 进入备份模式选择"
            echo "  list     -> 列出所有备份"
            echo "  doctor   -> 一键故障排除"
            exit 0 ;;
        *)  err "未知参数: $1"; exit 1 ;;
    esac
else
    [[ ! -d "$OC_DIR" ]] && { err "OpenClaw 目录不存在: $OC_DIR"; exit 1; }
    main_menu
fi