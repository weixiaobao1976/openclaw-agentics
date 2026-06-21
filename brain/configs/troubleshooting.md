# 🔧 OpenClaw 故障处理手册

> 目标：遇到问题 → 翻手册 → 30秒内定位 → 开始修复
> 每次新故障解决后，更新此文件。

---

## T-001：`agents.list` 类型错误（object ↔ array）

**严重性：** ⚠️ Gateway 启动失败，无法初始化 agent

### 现象

Gateway 启动日志报类似以下错误：

```
Cannot read properties of undefined (reading 'name')
TypeError: agents.list is not iterable
```

或配置校验阶段报 `agents.list` 类型非法。

### 根因

OpenClaw 配置中 `agents.list` **必须是数组（array）**，不是对象（object）。  
典型错误是把 `agents.list` 写成了：

```json
{
  "agents": {
    "list": {
      "name": "main",
      "workspace": "..."
    }
  }
}
```

而正确格式是：

```json
{
  "agents": {
    "defaults": { ... },
    "list": [
      {
        "name": "main",
        "workspace": "..."
      }
    ]
  }
}
```

### 发现方式

1. **Gateway 无法启动** — `systemctl --user status openclaw-gateway` 显示 failed
2. **日志检查** — `journalctl --user -u openclaw-gateway -n 50 --no-pager`
3. **配置检查** — `openclaw config get agents.list` 输出 `{...}`（object）而不是 `[...]`（array）

### 修复命令

```bash
# 用 jq 检查并修复
openclaw config get agents.list | jq type
# → 如果返回 "object"，需要改成 array

# 直接编辑修复（将 object 包装成单元素 array）
openclaw config set agents.list "[$(openclaw config get agents.list | jq -c)]"

# 或者手动编辑配置文件
# vim ~/.openclaw/openclaw.json
# 找到 "agents": { "list": { ... } } → 改成 "agents": { "list": [ { ... } ] }
```

### 验证命令

```bash
openclaw config get agents.list | jq type
# 必须返回 "array"

openclaw config validate
# 输出 "OK" 或空（无错误）

# 重启 Gateway
systemctl --user restart openclaw-gateway
systemctl --user status openclaw-gateway --no-pager | grep "Active:"
# 显示 active (running)
```

### 预防措施

- ✅ **改配置前跑 health-check 脚本**（见 `config/openclaw-config-health-check.sh`）
- ✅ 使用 `openclaw agents add` 而不是手动编辑 `agents.list`
- ✅ 在 CI/CD 或备份前加 `jq type` 校验
- ✅ 涉及 array/object 语义的字段，写注释标记（如 `# MUST be array`）

### 关联

- 本文：TROUBLESHOOTING.md
- 检查脚本：`config/openclaw-config-health-check.sh`
- 文档：`~/.openclaw/workspace/docs/` multi-agent.md

---

## T-000：Gateway 重启风暴（Restart Storm）

**严重性：** 🔴 Gateway 反复重启，服务不可用

### 现象

- `systemctl --user status openclaw-gateway` 显示不断重启
- `Active: activating (auto-restart) (RESULT: exit-code/signal)` 反复出现
- 短时间内 `Restart` 计数飙升

### 根因

`stale-cleanup.conf` 中的 `ExecStopPost` 使用了**通配符 kill**（`pkill` 或 `pgrep` 无端口过滤），导致：
1. 旧 Gateway 进程被 kill
2. systemd 启动新 Gateway
3. 新 Gateway 被前一步残留的 `ExecStopPost` 通配符杀掉
4. → 循环，重启风暴

### 发现方式

```bash
# 查看重启计数
systemctl --user show openclaw-gateway -p NRestarts

# 查看最近重启时间线
journalctl --user -u openclaw-gateway --since "5 minutes ago" | grep -E "Started|Stopped|Failed"

# 查看 stale-cleanup 日志
journalctl --user -u openclaw-gateway | grep "killing stale"
```

### 修复命令

```bash
# 修复 stale-cleanup：只按端口+精确PID kill
cat > ~/.config/systemd/user/openclaw-gateway.service.d/stale-cleanup.conf << 'EOF'
[Service]
# ✅ 安全：只杀掉监听 18789 端口的旧进程（精确PID匹配）
ExecStartPre=-/bin/bash -c 'for pid in $(ss -tlnp "sport = :18789" 2>/dev/null | grep -oP "pid=\K[0-9]+"); do echo "killing stale gateway pid=$pid"; kill "$pid" 2>/dev/null; sleep 1; done; exit 0'
ExecStartPre=/bin/sleep 3
# ❌ 移除通配符 ExecStopPost — 会误杀新进程
RestartSec=8
EOF

# 重载并重启
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway
```

### 验证命令

```bash
# 确认不再风暴
systemctl --user show openclaw-gateway -p NRestarts
# 数字应该稳定，不再增长

# 确认 Gateway 健康
systemctl --user status openclaw-gateway --no-pager | head -5
curl -s http://localhost:18789/health 2>/dev/null || echo "health endpoint not available"
```

### 预防措施

- ✅ **`ExecStopPost` 禁止使用通配符 kill**（`pkill`、`pgrep` 无参数）
- ✅ kill 前先确认端口匹配（`ss -tlnp "sport = :PORT"`）
- ✅ 增加 `RestartSec=8` 防止高频重启
- ✅ 设置 `TimeoutStartSec=15` 确保不会过早 abort

### 关联

- override 文件：`~/.config/systemd/user/openclaw-gateway.service.d/stale-cleanup.conf`
- 关联 override：`node-memory.conf`（内存限制）、`timeout.conf`（启动超时）

---

## 附录：故障速查索引

| 编号 | 故障名 | 关键症状 | 修复耗时 |
|------|--------|---------|---------|
| T-000 | Gateway 重启风暴 | Gateway 不断 restart | ~2min |
| T-001 | agents.list 类型错误 | Gateway 启动失败 | ~1min |

---

## 模板：添加新故障

```markdown
## T-XXX：故障名

**严重性：** 🔴/⚠️/🟢

### 现象

### 根因

### 发现方式

```bash
# 诊断命令
```

### 修复命令

```bash
# 修复步骤
```

### 验证命令

```bash
# 验证修复
```

### 预防措施
```

---

> 最后更新：2026-05-24 | 维护：小龙女