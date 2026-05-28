# OpenClaw 生态技术知识库

> 从 GitHub 爬取学习到的 OpenClaw 生态项目的架构模式、代码规范、最佳实践。
> 按项目整理，方便未来我快速检索。

---

## 一级项目（核心生态）

### 1. gogcli — Google Workspace CLI ⭐7,516

**语言:** Go
**仓库:** https://github.com/openclaw/gogcli
**文档:** https://gogcli.sh

**核心功能:** Gmail, Calendar, Drive, Docs, Sheets, Slides, Forms, Apps Script, Analytics, Search Console, Contacts, Tasks, Classroom, Chat, YouTube — 全 Google Workspace API

**学到的模式:**
- JSON-first 输出（`--json`=完整JSON stdout, `--plain`=摘要文本 stdout+JSON stderr）
- 多账号管理（`GOG_ACCOUNT` 环境变量切换）
- 多认证方式（OAuth / ADC / Service Account）
- Docker 支持（持久化卷+加密keyring）
- 安全剖面（命令allowlist/denylist + read-only审计模式）
- 自描述文档自动生成

### 2. mcporter — MCP CLI Tool ⭐4,483

**语言:** Node
**仓库:** https://github.com/openclaw/openclaw (skills/mcporter/)

**核心功能:** MCP 服务器CLI工具 — list/call/auth/config/daemon/codegen

**学到的模式:**
- CLI+MCP Server 双模式，同一套核心
- 6大模块：Call/Auth/Config/Daemon/Codegen
- 支持多种调用方式：key=value / 函数语法 / JSON / stdio
- `--output json` 优先于文本输出

### 3. Peekaboo — macOS 截图+VQA+自动化 ⭐4,439

**语言:** Swift + Node
**仓库:** https://github.com/openclaw/Peekaboo
**文档:** https://peekaboo.sh

**核心功能:** 屏幕截图 / 视觉问答 / GUI 自动化 / MCP Server

**学到的模式:**
- CLI命令 1:1 映射到 MCP Tool（一套核心两个入口）
- 多 AI Provider（OpenAI / Anthropic / 本地模型）
- Shell completions 自动生成
- 自然语言 Agent（`peekaboo agent "open Notes and ..."`）

### 4. wacli — WhatsApp CLI ⭐2,450

**语言:** Go
**仓库:** https://github.com/openclaw/openclaw (skills/wacli/)

**核心功能:** WhatsApp 收发消息、同步聊天历史

**学到的模式:**
- 安全约束在 SKILL.md 声明（"require explicit recipient + message text confirmation"）
- "When to Use / When NOT to Use" 区域设计
- 守护进程后台同步 + CLI 调用分离
- 分组消息支持（`--to "群组ID@g.us"`）

### 5. lobster — 工作流引擎 ⭐1,211

**语言:** TypeScript
**仓库:** https://github.com/openclaw/lobster

**核心功能:** JSON-typed pipeline / 工作流引擎 / approval gates

**学到的模式:**
- 管道基元：exec/where/pick/head/json/table/approve
- Typed pipelines (objects/arrays) — 不是文本管道
- 审批门：副作用操作自动 halt 等待人工确认
- 可恢复（resumable）：token 驱动，不用全部重跑
- 本地优先：不创建新的认证面

### 6. imsg — iMessage CLI ⭐1,124

**语言:** Go + Swift
**仓库:** https://github.com/openclaw/imsg
**文档:** https://imsg.sh

**核心功能:** iMessage/SMS 收发、历史查询、实时监控

**学到的模式:**
- 双栈架构：公共层(AppleScript) + 高级层(IMCore dylib注入)
- 本地优先：直接读 `~/Library/Messages/chat.db`
- Filesystem 事件流（watch）+ fallback 轮询
- 完整 JSON Schema（`imsg completions llm` 为 AI 生成 CLI 帮助）
- 附件自动转换（CAF→M4A / GIF→PNG）

### 7. openclaw-ansible — 自动部署 ⭐581

**语言:** Ansible
**仓库:** https://github.com/openclaw/openclaw-ansible

**核心功能:** 自动安装 OpenClaw（Tailscale + UFW + Docker + Fail2ban）

**学到的模式:**
- 多层次安全：Tailscale VPN → UFW防火墙 → Fail2ban → unattended-upgrades → Docker隔离
- 专用系统用户 `openclaw`
- `pnpm install -g openclaw@latest` 从 npm 安装
- macOS 部署已废弃 → 只支持 Debian/Ubuntu
- `openclaw onboard --install-daemon` 一键启动

---

## 二级项目（社区生态 + 相关生态）

### 8. gbrain — OpenClaw/Hermes 大脑 ⭐18,240
**作者:** Garry Tan（Y Combinator CEO）
**仓库:** https://github.com/garrytan/gbrain
**核心:** 自接线知识图谱 + 混合搜索 + 结构化时间线

**学到的模式:**
- 自接线知识图谱：写入时自动提取实体，创建 typed links（`attended`, `works_at`, `invested_in`, `founded`, `advises`）
- 零 LLM 调用的实体提取和关系构建
- 混合搜索（向量 + 结构化链接 + 反向链接权重排序）
- 自主运行：夜间自动整理记忆、修复引用、合并实体
- 真实规模：146,646 页面 / 24,585 人 / 5,339 公司 / 66 个 cron job

**对我最直接的启发：** AGENTS.md 中的反向链接模式 + memory_search 的混合检索

### 9. OpenViking — AI Agent 上下文数据库 ⭐24,524
**来源:** 字节跳动 (volcengine)
**仓库:** https://github.com/volcengine/OpenViking
**核心:** 文件系统范式的上下文管理

**学到的模式:**
- 文件系统范式：memory/resource/skill 按文件系统层级管理
- 层次化上下文传递（hierarchical context delivery）
- 可观察的检索链（不是黑盒 RAG）
- 自进化能力（self-evolving）：任务记忆超出纯用户交互记录
- 解决的核心问题：碎片化上下文、信息丢失、检索黑盒、记忆不可迭代

### 10. planning-with-files — 持久化 Markdown 规划 ⭐21,895
**来源:** OthmanAdi
**仓库:** https://github.com/OthmanAdi/planning-with-files
**核心:** Manus 风格的持久化 Markdown 规划文件

**学到的模式:**
- 规划即文件：用 markdown 文件创建持久化任务计划
- 跨会话持久：计划不随对话结束消失
- `update_plan` 工具的用途加深理解

### 11. zeroclaw — 轻量 Rust 版 OpenClaw ⭐31,535
**来源:** zeroclaw-labs
**仓库:** https://github.com/zeroclaw-labs/zeroclaw
**核心:** Rust 实现的高性能 OpenClaw，部署到哪里都可以

### 12. nanoclaw — 容器化轻量 OpenClaw ⭐29,286
**来源:** nanocoai
**仓库:** https://github.com/nanocoai/nanoclaw
**核心:** Docker 隔离运行，底层 Anthropic Agents SDK

### 13. NemoClaw — NVIDIA 安全 OpenClaw ⭐20,605
**来源:** NVIDIA
**仓库:** https://github.com/NVIDIA/NemoClaw
**核心:** OpenShell 托管的安全运行环境

### 14. awesome-openclaw-usecases — 社区用例集 ⭐31,152
**来源:** hesamsheikh
**仓库:** https://github.com/hesamsheikh/awesome-openclaw-usecases
**核心:** OpenClaw 实用场景集合

### awesome-openclaw-skills ⭐49,200
**来源:** https://github.com/VoltAgent/awesome-openclaw-skills

5300+ 社区技能的索引目录，25+ 分类（GitHub/DevOps/Monitoring/AI/Calendar 等）
**学到的模式:** 大型技能目录的分类学和组织结构

### OpenClaw 官方扩展（extensions/ 目录）
**来源:** openclaw/openclaw GitHub

100+ 官方扩展，覆盖：
- 模型提供商：DeepSeek / NVIDIA / Minimax / Grok / Gemini / Qwen 等
- 聊天平台：Telegram / Discord / WhatsApp / Signal / Slack / 飞书 等
- 内存系统：Mem0 / Memory 等

---

## 🧠 我自己的运用状态

| 模式 | 已植入 | 状态 |
|------|--------|------|
| JSON-typed Pipeline | TOOLS.md | ✅ 已记录 |
| JSON-first 输出 | TOOLS.md | ✅ 已记录 |
| 安全约束声明 | TOOLS.md | ✅ 已记录 |
| CLI↔Tool 双模式 | TOOLS.md | ✅ 已记录 |
| 本地优先 | TOOLS.md | ✅ 已记录 |
| 自我强化循环 | AGENTS.md | ✅ 已记录 |
| MEMORY.md | 创建完成 | ✅ 已记录 |