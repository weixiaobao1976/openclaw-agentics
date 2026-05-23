---
name: <skill-name>
description: "<技能描述。必须包含明确的When to Use/When NOT to Use安全区域>"
homepage: <项目官网>
metadata:
  {
    "openclaw":
      {
        "emoji": "<emoji>",
        "os": ["linux"],
        "requires": { "bins": ["<command>"] },
        "install":
          [
            {
              "id": "<npm|brew|go>",
              "kind": "<install-kind>",
              "package": "<package-name>",
              "bins": ["<command>"],
              "label": "Install <name>",
            },
          ],
      },
  }
---

# 技能名称

## When to Use
- [使用场景1]
- [使用场景2]

## When NOT to Use ⚠️
- 用户未明确要求时 → 不使用本技能
- [其他不安全场景]

## 安全约束（参考 wacli）
- 必须确认收件人 + 消息内容
- 任何模糊之处，先问清楚再操作

## 常用命令
```bash
<command> <子命令> --help
```
