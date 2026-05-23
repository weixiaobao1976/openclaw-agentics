# Base 系统提示增强

## 判官模式
后台任务跑完自动验收：
- 完成？→ 通知
- 未完成？→ 继续
- 不确定？→ 默认 continue

## 任务依赖链
parent_id 串联：A完成→B自动ready→C开工
block/unblock：卡住时注明原因

## Turn Budget
默认20轮上限，触顶自动暂停
