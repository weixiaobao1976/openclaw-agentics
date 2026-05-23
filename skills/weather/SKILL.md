---
name: weather
description: "Weather forecasts with wttr.in via curl. Supports retry on network errors."
---

# Weather — 天气预报

```bash
# 简单查询
curl "wttr.in/Shanghai?format=%l:+%c+%t"
curl "wttr.in/London?0"

# 详细 JSON
curl "wttr.in/Huadu?format=j1"

# 带重试的封装脚本
node ~/.openclaw/scripts/weather-forecast.js
```
