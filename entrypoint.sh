#!/usr/bin/env bash
set -e

# 1. 确保 SSH 运行所需目录存在
mkdir -p /run/sshd

# 2. 持久化 SSH Host Keys，避免容器重建后本地报 "REMOTE HOST IDENTIFICATION HAS CHANGED"
HOST_KEYS_BACKUP_DIR="/root/.ssh/host_keys"
mkdir -p "${HOST_KEYS_BACKUP_DIR}"

if ls "${HOST_KEYS_BACKUP_DIR}"/ssh_host_*_key >/dev/null 2>&1; then
    # 从持久化卷恢复 Host Keys
    cp -f "${HOST_KEYS_BACKUP_DIR}"/ssh_host_* /etc/ssh/ 2>/dev/null || true
    chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
    chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null || true
else
    # 首次启动：生成并备份到持久化卷
    ssh-keygen -A >/dev/null 2>&1 || true
    cp -f /etc/ssh/ssh_host_* "${HOST_KEYS_BACKUP_DIR}/" 2>/dev/null || true
fi

# 3. 严格校准 .ssh 目录和 authorized_keys 权限 (OpenSSH 拒绝非安全权限)
mkdir -p /root/.ssh
chmod 700 /root/.ssh
if [ -f /root/.ssh/authorized_keys ]; then
    chmod 600 /root/.ssh/authorized_keys
fi

# 4. 启动 SSH 守护进程 (后台运行)
/usr/sbin/sshd

# 5. 执行原前台任务 (如 code serve-web)
exec "$@"
