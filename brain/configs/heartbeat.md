# HEARTBEAT Tasks

## 🔍 检查 OpenRouter 免费模型更新（约每30分钟）
- 执行 `node ~/.openclaw/scripts/check-free-models.mjs`
- 如果 rc=1（有变化）→ 解析 stdout 中的 `HEARTBEAT_OR_CHANGE:`，把新增/下架的模型通知给主人
- 如果 rc=0（无变化）→ 静默跳过，不需要汇报
- 如果连接失败/超时 → 静默跳过