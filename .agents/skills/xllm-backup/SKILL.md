---
name: xllm-backup
description: Configure and manage automatic backups of the xllm repository to a personal GitHub account using SSH over port 443. Use when the user asks about backing up xllm, setting up auto-push, fixing GitHub push failures, or managing the backup script on a shared root server with restricted GitHub HTTPS access.
---

# xllm 自动备份到个人 GitHub 仓库

## 何时使用

- 在共享 root 服务器上开发 xllm
- 需要防止代码被误删除或丢失
- 网络环境无法直接访问 GitHub，但 SSH over 443 可用

## 前置条件

- 代码仓位于 `/opt/jyf/xllm`
- 已 fork 个人 GitHub 仓库（如 `Fengfengst123/xllm`）
- origin remote 指向个人仓库

## 核心原理

| 操作 | 协议 | 通道 |
|------|------|------|
| fetch/pull | HTTPS | `gh-proxy.com` 镜像加速 |
| push | SSH over 443 | 直连 GitHub，绕过防火墙 |

所有 SSH 配置**隔离在代码仓 `.ssh/` 目录内**，不污染系统 `/root/.ssh/`。

## 一键配置

```bash
cd /opt/jyf/xllm

# 1. 生成密钥
mkdir -p .ssh && chmod 700 .ssh
ssh-keygen -t ed25519 -f .ssh/id_ed25519 -N ""

# 2. 复制公钥到 GitHub -> Settings -> SSH and GPG keys -> New SSH key
cat .ssh/id_ed25519.pub

# 3. 写 SSH 配置
cat > .ssh/config << 'EOF'
Host github.com
    HostName ssh.github.com
    Port 443
    User git
    IdentityFile /opt/jyf/xllm/.ssh/id_ed25519
    UserKnownHostsFile /opt/jyf/xllm/.ssh/known_hosts
    StrictHostKeyChecking accept-new
EOF

# 4. 写 wrapper
cat > .ssh/git-ssh-wrapper << 'EOF'
#!/bin/bash
exec ssh -F /opt/jyf/xllm/.ssh/config "$@"
EOF
chmod +x .ssh/git-ssh-wrapper

# 5. 获取 host key
ssh-keyscan -p 443 ssh.github.com > .ssh/known_hosts

# 6. 设置 push 走 SSH
git remote set-url --push origin git@github.com:Fengfengst123/xllm.git

# 7. 验证
GIT_SSH=/opt/jyf/xllm/.ssh/git-ssh-wrapper git push -u origin main
```

## 启动自动备份

```bash
cd /opt/jyf/xllm
chmod +x auto_push.sh
nohup ./auto_push.sh > auto_push.log 2>&1 &
```

## 常用命令

```bash
# 查看日志
tail -f /opt/jyf/xllm/auto_push.log

# 查看进程
ps aux | grep auto_push.sh

# 停止备份
kill <PID>

# 手动推送
export GIT_SSH=/opt/jyf/xllm/.ssh/git-ssh-wrapper
git push origin main
```

## 安全规则

- `chmod 600 .ssh/id_ed25519 .ssh/config .ssh/known_hosts`
- 禁止将私钥复制到代码仓外部（尤其 `/root/.ssh/`）
- 定期检查 `auto_push.log` 确认备份成功

## 常见问题

**Q: push 返回 `Premature close`**
A: 确认未使用 HTTPS push。检查 `git remote -v`，push URL 必须是 `git@github.com`。

**Q: `Host key verification failed`**
A: 重新获取 host key：`ssh-keyscan -p 443 ssh.github.com > .ssh/known_hosts`

**Q: 自动脚本不提交代码**
A: 检查是否有 pre-commit hook 卡住，可临时禁用：
`mv .git/hooks/pre-commit .git/hooks/pre-commit.bak`
