## Build
```shell
# 格式化为 年月日-时分秒，例如：chet2026/cdev:20260824-111834
TAG=$(date +%Y%m%d-%H%M%S)
docker build -t chet2026/cdev:${TAG} .
docker push chet2026/cdev:${TAG}

```
## Run
```shell


# 1. 自动将当前目录路径转换为安全的容器名
CONTAINER_NAME="cdev-$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')"

# 2. 检查并确保 systemd linger 开启（防止关闭终端时容器收到 SIGTERM 异常退出）
if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$(whoami)" 2>/dev/null || true
fi

# 3. 清理同名的旧容器（防止重名冲突报错）
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# 4. 运行容器（直接使用 Dockerfile 中写死的 CMD，无需重复编写）
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 8080:8000 \
  -v "$(pwd)":/workspace \
  --restart unless-stopped \
  chet2026/cdev:latest

echo "------------------------------------------------"
echo "✅ Cdev started successfully!"
echo "🌐 Access via: http://localhost:8080/?folder=/workspace
echo "📂 Workspace:  $(pwd)"
echo "------------------------------------------------"


```
