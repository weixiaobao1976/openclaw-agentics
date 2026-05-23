# 🤖 OpenClaw 技能源码与 Agent 增强

> 自定义 skills / 自动化工作流 / agent 能力增强

## 📋 分支规划

| 分支 | 内容 |
|------|------|
| `main` | 总览 + 索引 |
| `skills` | 自定义技能源码（gh-ops/github-search/weather 等）|
| `automation` | 自动化工作流（cron/flows/定时任务）|
| `agent-enhance` | Agent 增强（系统提示词优化/工具链扩展）|
| `templates` | 技能开发模板 |

## 🎯 核心技能

| 技能 | 用途 | 位置 |
|------|------|------|
| `gh-ops` | GitHub 全操作（仓库/issue/PR/CI/release） | `skills/gh-ops/` |
| `github-search` | GitHub 仓库深度搜索 | `skills/github-search/` |
| `github-trending-cn` | GitHub 趋势中文分析 | `skills/github-trending-cn/` |
| `weather` | 天气预报（含重试+容错） | `skills/weather/` |

## 🧠 Agent 增强体系

### 系统提示词优化

```
agent-enhance/prompts/
├── base.md          # 基础系统提示（SOUL.md 增强版）
├── role-researcher  # 研究员角色 prompt
├── role-analyst     # 分析师角色 prompt
└── role-writer      # 写手角色 prompt
```

### 判官/验证机制

基于 Hermes /goal 模式，后台任务配备验收函数：

```
任务执行 → 每轮判官评估 →
  达成目标？ → 通知 + 停止
  未达成？   → 自动续下一轮
  不确定？   → 默认 continue
```

### 任务依赖链

```
researcher → analyst → writer
  R1完成 → R2自动ready → dispatcher调度 → R3开工
block/unblock 模式：卡住时 block 并注明原因
```

## 🔧 技能开发模板

```bash
# 快速创建新技能
./templates/create-skill.sh my-skill "技能描述"
```

模板结构：
```
templates/skill/
├── _meta.json          # 元数据模板
├── SKILL.md            # YAML frontmatter + 操作指南
└── scripts/
    └── placeholder.mjs # 脚本模板
```

## 🔗 相关项目

- [openclaw-tools](https://github.com/weixiaobao1976/openclaw-tools) — 运维工具集
- [openclaw-web](https://github.com/weixiaobao1976/openclaw-web) — Web 管理界面
- [openclaw-techniques](https://github.com/weixiaobao1976/openclaw-techniques) — 技术实战文档库

---

**不断进化，持续增强** 🐺