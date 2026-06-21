# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## 🧠 核心操作模式（已植入自身）

### 模式1: JSON-typed Pipeline（来自 lobster）

**核心原则：** 多步任务用 pipeline 模式组织，每一步都是结构化 JSON 输入/输出，不自创临时格式。

```
运维 pipeline：
  step1: health-check        → JSON 状态报告
  step2: 判官判断是否正常     → pass / fail
  step3: fail 则自动修复      → JSON 修复结果 + notify
  step4: pass 则记录状态      → 写入 memory
```

**审批门（Approval Gate）：** 高风险操作（删文件/发消息/改配置）自动 halt，等主人确认再继续。

### 模式2: JSON-first 输出（来自 gogcli）

**输出规范：**
- `stdout` → 结构化 JSON 数据（机器可解析）
- `stderr` → 人类可读的摘要/提示
- 默认模式输出 JSON，`--pretty` 输出格式化 JSON，`--plain` 输出人类摘要

### 模式3: "When to Use / When NOT to Use" 安全约束（来自 wacli）

在发起任何可能产生外部效果的操作前：
1. 检查是否属于"不该用"的场景 → 跳过
2. 需要确认的操作 → 先问主人
3. 模糊不清 → 不猜，先确认

### 模式4: CLI ↔ Tool 双模式（来自 Peekaboo/mcporter）

同一套核心逻辑，提供：
- 自然语言调用（日常聊天）
- 结构化 API 调用（子代理/脚本场景）
- 两套入口共享同一套安全检查

### 模式5: 本地优先（来自 imsg/lobster）

能读本地文件解决的，不调远程 API。能本地执行的，不依赖外部服务。
多步任务用 pipeline 组织而不是靠记忆来回跳。

### 模式6: 自接线知识图谱（来自 gbrain）

写入文件时自动建立实体间的 typed links：人和组织（works_at/founded），项目和事件（related_to/depends_on），时间上下文（happened_on）。原则：写的时候顺便建连接，不额外调 LLM。

### 模式7: 层次化上下文（来自 OpenViking）

knowledge/ 目录按层级分：techniques（长期稳定）、ecosystem（中期参考）、daily（短期可压缩）。每层不同保留策略和检索优先级。

### 模式8: 持久化规划（来自 planning-with-files）

复杂任务用 `update_plan` 创建规划文件。规划是文件不是上下文记忆，跨会话持续存在，每步后更新进度，完成后归档。

---

## 从外部文章学到的模式

### 判官/验证机制（来自 Hermes /goal）

跑后台任务时，不要只靠"跑完了通知我"——用验收函数判断是否真正达成，再通知主人。

**原则：不确定就继续跑，不确定就继续跑。** 只有明确完成或明确无法推进才停。

```
目标设定 → 每轮结束判官评估 →
  完成？ → 通知 + 停止
  未完成？ → 自动续下一轮（不用人催）
  判官出错？ → 默认当 continue 处理，不卡死
```

### 任务依赖链（来自 Hermes Kanban）

A 完成后 B 才开工，B 完成后 C 才开工。用 `parent_id` 串联。

```
researcher → analyst → writer
   R1完成 → R2自动ready → dispatcher调度 → R3开工
```

**block/unblock 模式：** 任务卡住时 block 并注明原因，补齐资料后 unblock 继续。

### Profile + SOUL.md 分角色（来自 Hermes profile）

spawn 子任务时，给它设定角色 prompt 而不是都用同一个语气。

```
researcher: 擅长搜集原始资料、核实事实，输出要点列表+来源
analyst:     提炼核心，整理逻辑，输出结构化分析
writer:      擅长把技术内容写成易懂文章，输出公众号风格
```

### Turn Budget + 保守策略

设定最大轮次上限（默认20），触顶自动暂停。判官不确定就继续跑，不会误判早停。

### Claude Code 斜杠命令 + Skills 系统

**斜杠命令：** 触发多步工作流，不只是单次 prompt。包含文件生成、Git 操作、API 调用的完整任务流。

**Skills：** 可复用的 Agent 技能包。每个 Skill 有自己的提示词、模板、评分标准。子代理用 YAML 配置专属系统提示词、工具集、权限、模型选择。

```
/code-review  → 自动审查，输出结构化报告
/bug-hunt     → 定位 + 修复 Bug
/test-engineer → 单元测试 + 集成测试
/doc-writer   → 技术文档，按品牌风格输出
```

**核心思路：** 把 AI 打造成多专家协作团队。不用每次从头写提示词，调用 Skill 自动进入专家模式。

### Claude Code 记忆系统

项目记忆（CLAUDE.md）放在项目根目录，AI 每次启动自动读取。包含项目背景、团队规范、技术栈约束、anti-patterns。

**效果：** AI 不再是"每次从零开始"。上下文理解能力是 AI 编程效率质变的第一步。

### Claude Code Hooks 自动触发器

在特定时机自动触发脚本：提交前、工具执行前、会话结束等。支持 command / http / prompt / mcp_tool / agent 等触发类型。

```
pre-commit:   自动检查格式 + 安全问题
pre-tool:     追踪 token 使用量，避免上下文溢出
post-exec:    记录 Bash 操作日志，发送会话总结
```

**核心思路：** 不是需要人盯着操作的工具，而是自动化运行的系统。

### MCP（Model Context Protocol）

连接外部工具和 API 的标准协议。接入后 AI 可以直接操作 GitHub、数据库、飞书等——不是 API 调用，而是作为原生工具来用。

**升级路径：** AI 编程从"在代码里用 AI" → "用 AI 操作整个开发环境"。

### 规划模式（Planning Mode）

复杂任务先让 AI 制定执行计划，人批准后再开始执行。不是一上来就动手，而是先对齐方向。

**适用场景：** 风险高、不可逆、多步骤的任务。

### Auto Mode + 安全分类器

每次操作前跑后台安全分类器，通过了才执行。处理敏感操作时自动开启保护机制。

**思路：** 让 AI 做事之前先过一遍安全检查，不是事后补救。

### 后台任务（不阻塞）

长时间任务放后台，不卡住当前对话，完成后自动通知。

**和我现在 sessions_spawn 的区别：** 我用的是 yieldMs 等待，Auto Mode 是纯后台不阻塞 + push 通知。

### 权限模式（Permission Modes）

从 default 到 bypassPermissions，从每次确认到完全放权，按需配置。

**实操：** 对低风险任务开 bypass，减少确认噪音；对高风险操作保留 default。

### 插件打包（Plugin System）

把多个 Skills + Hooks + 子代理 + MCP 配置打包成分发单元。团队新人装了插件，等于拥有整个团队的能力。

```
pr-review 插件示例：
  - 3个子代理（性能分析/安全审查/测试覆盖）
  - 3个命令（/review-pr /check-security /check-tests）
```

**核心思路：** 不是培训赋能，是工具赋能。装上就有，不用学。

### 流水线模式：发现→整理→输出

```
GitHub Trend Scout（发现）
  → Knowledge Agent（整理到笔记库）
    → Writing Agent（输出文章）
      → 人（判断+审稿）
```

**分工原则：** 信息发现和研究整理不需要人亲自动手，人只做判断和最终输出。

### 情景化技能组合（来自 OpenClaw 必装组合）

不追求全装，按场景选组合，效率更高。

```
日常行政/汇报：ClawHub + 搜索 + Summarize + Data Analyst + 飞书
市场/运营：搜索 + Agent Browser + Summarize + Notion
管理层/跨部门：搜索 + Data Analyst + 飞书 + Proactive-agent
```

**原则：** 稳定联网是基础，先把地基打好再加功能。

---

Add whatever helps you do your job. This is your cheat sheet.
