#!/bin/bash
# xllm 自动推送脚本：每30分钟自动提交并推送到 origin main

set -e

REPO_DIR="/opt/jyf/xllm"
INTERVAL=1800  # 30分钟

while true; do
    cd "$REPO_DIR"

    # 自动添加所有变更
    git add -A

    # 提交（如果没有变更，commit 会退出码 1，用 || true 忽略）
    git commit -m "auto push at $(date '+%Y-%m-%d %H:%M:%S')" || true

    # 推送到 origin main
    # 用 -c 临时清空 insteadOf，避免走只读镜像代理（gh-proxy 不支持 push）
    git -c url."https://github.com/".insteadOf= push origin main || echo "[$(date '+%H:%M:%S')] push failed, retry next loop"

    echo "[$(date '+%H:%M:%S')] next push in 30min..."
    sleep "$INTERVAL"
done
