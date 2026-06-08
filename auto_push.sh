#!/bin/bash
# xllm 自动备份脚本：每30分钟自动提交并推送到个人 GitHub 仓库
# 注意：所有 SSH 配置隔离在代码仓 .ssh/ 目录内，不影响系统及其他用户

set -e

REPO_DIR="/opt/jyf/xllm"
INTERVAL=1800  # 30分钟

# 使用代码仓内部的 SSH wrapper，避免污染系统 /root/.ssh/
export GIT_SSH="$REPO_DIR/.ssh/git-ssh-wrapper"

while true; do
    cd "$REPO_DIR"

    # 获取远程最新状态（fetch 走 HTTPS 镜像代理加速）
    git fetch origin 2>/dev/null || echo "[$(date '+%H:%M:%S')] fetch warning"

    # 自动暂存所有变更（包括新增、修改、删除）
    git add -A

    # 提交（如无变更则跳过）
    git commit -m "auto backup at $(date '+%Y-%m-%d %H:%M:%S')" || true

    # 推送到 origin main（走 SSH over 443 绕过网络限制）
    git push origin main || echo "[$(date '+%H:%M:%S')] push failed, will retry next loop"

    echo "[$(date '+%H:%M:%S')] next backup in 30min..."
    sleep "$INTERVAL"
done
