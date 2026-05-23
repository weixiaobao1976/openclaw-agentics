# Lobster 工作流模板

## 模式: JSON-typed Pipeline

参考 lobster 的设计原则:
- 管道基元: exec → where → pick → head → json/table
- 每一步的输入/输出都是 JSON 对象，不是文本流
- 副作用操作需要 approval gate

## 运维流水线示例

### 部署流水线（含审批门）
```
1. 代码检查 lint       → JSON 报告
2. 单元测试 test       → JSON 测试结果
3. 审批门 approve       → 等待人工确认
4. 构建 build          → 制品JSON
5. 部署 deploy         → 部署确认
6. 健康检查 health      → JSON 状态报告
```

### 备份流水线
```
1. 收集文件 collect     → 文件列表 JSON
2. 压缩打包 archive     → 存档元数据 JSON
3. 上传到备份存储 upload → 上传确认
4. 校验验证 verify      → 校验结果 JSON
5. 通知通知 notify      → 通知发送状态
```
