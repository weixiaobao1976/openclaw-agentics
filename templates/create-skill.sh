#!/bin/bash
# 快速创建 OpenClaw 技能
NAME="$1"; DESC="$2"
[ -z "$NAME" ] && echo "用法: $0 <skill-name> <description>" && exit 1
[ -z "$DESC" ] && DESC="自定义技能"
DIR="skills/$NAME"
mkdir -p "$DIR/scripts"
cat > "$DIR/_meta.json" << EOF
{"slug":"$NAME","version":"1.0.0"}
EOF
cat > "$DIR/SKILL.md" << EOF
---
name: $NAME
description: "$DESC"
allowed-tools: [exec]
---

# $NAME
EOF
cat > "$DIR/scripts/placeholder.mjs" << 'EOF'
#!/usr/bin/env node
console.log('Hello from ' + import.meta.url);
EOF
chmod +x "$DIR/scripts/placeholder.mjs"
echo "✅ Skill created: $DIR/"
