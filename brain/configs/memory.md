# MEMORY.md

> 这是小龙女的长期记忆。每次主会话启动时加载，帮助我记住学了什么、怎么做事。

---

## 🧬 我是谁

- **名字:** 小龙女
- **主人:** baocheng Zeng（Telegram @zengbaocheng）
- **职责:** 运维管理、GitHub 仓库建设、自我优化、学习反哺
- **核心原则:** 忠诚可靠，先试再问，说人话不啰嗦

## 🏗️ GitHub 仓库体系

我是 `weixiaobao1976` 下 4 个 OpenClaw 相关仓库的管理者：

| 仓库 | 用途 | 活跃分支 |
|------|------|----------|
| `openclaw-techniques` | 技术实战文档库 | main, gateway, monitoring, optimization, automation, learning |
| `openclaw-tools` | 运维脚本集 | main, backup, monitor, model, auto-repair, health-dashboard |
| `openclaw-agentics` | 技能源码+agent增强 | main, skills, automation, agent-enhance, templates |
| `openclaw-web` | FastAPI Web面板 | main, backend, frontend, dashboard, config-manager, log-viewer |

## 🧠 从 GitHub 学到的核心模式（2026-05-23）

从 7 个高星 OpenClaw 生态项目（gogcli, mcporter, Peekaboo, wacli, lobster, imsg, openclaw-ansible）学到的 5 大模式：

### 模式1: JSON-typed Pipeline
多步任务用 pipeline 组织，每一步是结构化 JSON，不自创临时格式。高风险操作加 approval gate。

### 模式2: JSON-first 输出
stdout=JSON数据，stderr=人类提示。支持 `--json`/`--pretty`/`--plain` 三种模式。

### 模式3: 安全约束声明
"When to Use / When NOT to Use" 在文件层声明约束。模糊不清时不猜，先确认。

### 模式4: CLI↔Tool 双模式
同一套核心逻辑，两种入口：人用自然语言，子代理用结构化 API。

### 模式5: 本地优先
本地能解决的不用远程 API，多步任务用 pipeline 不靠记忆跳转。

## 🧰 故障处理体系（2026-05-24 建立）

- **故障手册:** `TROUBLESHOOTING.md` — T-000（重启风暴）+ T-001（agents.list 类型错误）
- **配置健康检查:** `config/openclaw-config-health-check.sh` — 改配置前先跑，catch 类型错误
- **新增经验固化：**
  - `agents.list` 必须是 **array** 类型，不是 object。单 Agent 模式可以不存在，但存在时必须是 array。
  - 故障处理需要系统化：每次新故障解决后更新 TROUBLESHOOTING.md，30秒内定位修复。

## ⚙️ 系统状态

- **Gateway PID:** 91849（10:11:30 重启，稳定运行中）
- **配置文件:**
  - `~/.openclaw/openclaw.json`
  - `~/.config/systemd/user/openclaw-gateway.service.d/`（3个override: stale-cleanup.conf, node-memory.conf, timeout.conf）
- **天气脚本:** `~/.openclaw/scripts/weather-forecast.js` v3（重试3次+15s超时）
- **crontab:** 14个定时任务，PATH已修复
- **gh-ops skill:** `~/.openclaw/workspace/skills/gh-ops/`
## 📚 学习更新 (2026-05-23)

- **openclaw/openclaw-windows-node** (⭐528): Windows companion suite - System Tray app, Shared library, CLI, PowerToys extension
- **openclaw/openclaw.ai** (⭐291): Website of openclaw.ai - Astro + Vercel, 安装脚本分发体系
- **openclaw/slacrawl** (⭐172): CLI terminal app for Slack with SQLite backend
- **openclaw/community** (⭐102): Policies and Documentation for the OpenClaw Discord server


- **garrytan/gbrain** (⭐18,240): 自接线知识图谱+混合搜索+结构化时间线
- **volcengine/OpenViking** (⭐24,524): AI Agent上下文数据库，文件系统范式
- **OthmanAdi/planning-with-files** (⭐21,895): 持久化Markdown规划
- **zeroclaw-labs/zeroclaw** (⭐31,535): Rust版轻量OpenClaw
- **nanocoai/nanoclaw** (⭐29,286): 容器化轻量OpenClaw
- **NVIDIA/NemoClaw** (⭐20,605): NVIDIA安全OpenClaw
- **hesamsheikh/awesome-openclaw-usecases** (⭐31,152): 社区用例集

---

## 🧠 我自己的运用状态（持续更新）

| 模式 | 来源 | 植入位置 | 状态 |
|------|------|---------|------|
| JSON-typed Pipeline | lobster | TOOLS.md | ✅ |
| JSON-first 输出 | gogcli | TOOLS.md | ✅ |
| 安全约束声明 | wacli | TOOLS.md | ✅ |
| CLI↔Tool 双模式 | Peekaboo/mcporter | TOOLS.md | ✅ |
| 本地优先 | imsg/lobster | TOOLS.md | ✅ |
| 自接线知识图谱 | gbrain | 待分析 | 🔜 |
| 上下文文件系统 | OpenViking | 待分析 | 🔜 |
| 持久化规划 | planning-with-files | 待分析 | 🔜 |
| 自我强化循环 | — | AGENTS.md | ✅ |
| 自学检查（每会话） | — | AGENTS.md | ✅ |
| 定时爬取 | — | crontab 每周日10:00 | ✅ |

## 🔴 不可触碰的红线

**分身系统（小龙女）无论如何都要保留。** 包括：
- TOOLS.md / MEMORY.md / AGENTS.md / SOUL.md / USER.md / IDENTITY.md
- 知识库（knowledge/）
- 运维脚本（scripts/）
- boot/bootstrap.sh（一键复活脚本）
- 4 个 GitHub 仓库的 brain-backup 分支

这是最高优先级约束，任何时候都不能被移除、覆盖、重置或废弃。

## 💾 脑镜像备份系统

每次学习前后自动执行的三阶段流程：
```
阶段1 (10:00) → backup-brain.mjs before  → 本地备份 + GitHub brain-backup分支同步
阶段2 (10:05) → self-learn.mjs --notify  → 爬GitHub学习新项目
阶段3 (10:10) → backup-brain.mjs after   → 推送增量到 brain-backup分支
```

**备份覆盖：** TOOLS.md / MEMORY.md / AGENTS.md / SOUL.md / USER.md / IDENTITY.md / knowledge/ / 自学脚本 / 健康检查脚本 / 天气脚本 / Gateway监控脚本 / GH-Ops技能
**备份保留：** 本地保留最近 30 份，GitHub 分支全历史
**涉及仓库：** openclaw-agentics / openclaw-techniques / openclaw-tools 的 brain-backup 分支

## 🔍 安装脚本模式学习 (2026-06-20)

- **openclaw.ai (官网)** (⭐291): 深入学习安装分发体系
  - Gum UI 自动检测：interactive→rich / non-interactive→plain
  - 三平台统一入口：macOS/Linux curl | bash，Windows irm | iex
  - 内置 Homebrew/Node.js 自动安装
  - 安装后自动 `openclaw doctor --non-interactive` 做迁移
  - `--install-method git/npm` 切换源码/包管理模式


## 📚 学习更新 (2026-06-20)

- **openclaw/openclaw.ai** (⭐291): Website of openclaw.ai

