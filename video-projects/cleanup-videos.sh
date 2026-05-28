#!/bin/bash
# HyperFrames 视频自动清理脚本
# 功能：删除超过7天的输出视频，保留源文件

VIDEO_DIR="/home/zbc2/.openclaw/workspace/video-projects"
DAYS=7
LOG_FILE="/home/zbc2/.openclaw/workspace/video-projects/cleanup.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 统计删除的文件
deleted_count=0
deleted_size=0

log "=== 开始清理任务 ==="
log "目标目录: $VIDEO_DIR"
log "保留天数: $DAYS 天"

# 查找并删除超过7天的 MP4 文件
while IFS= read -r file; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || echo 0)
        deleted_size=$((deleted_size + size))
        rm -f "$file"
        log "已删除: $file (大小: $((size/1024/1024))MB)"
        deleted_count=$((deleted_count + 1))
    fi
done < <(find "$VIDEO_DIR" -name "*.mp4" -type f -mtime +$DAYS 2>/dev/null)

# 清理空目录
while IFS= read -r dir; do
    if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
        :  # 目录非空
    elif [ -d "$dir" ]; then
        rmdir "$dir" 2>/dev/null && log "已删除空目录: $dir"
    fi
done < <(find "$VIDEO_DIR" -type d -empty 2>/dev/null)

# 清理 temp 目录（始终清空）
if [ -d "$VIDEO_DIR/temp" ]; then
    temp_count=$(find "$VIDEO_DIR/temp" -type f 2>/dev/null | wc -l)
    if [ "$temp_count" -gt 0 ]; then
        rm -rf "$VIDEO_DIR/temp"/*
        log "已清空 temp 目录 ($temp_count 个文件)"
    fi
fi

# 统计结果
total_size_mb=$((deleted_size/1024/1024))
log "=== 清理完成 ==="
log "删除文件: $deleted_count 个"
log "释放空间: $total_size_mb MB"

# 输出摘要
echo ""
echo "================================"
echo "  清理完成"
echo "================================"
echo "  删除文件: $deleted_count 个"
echo "  释放空间: $total_size_mb MB"
echo "================================"