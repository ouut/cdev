## Build
```shell
# 格式化为 年月日-时分秒，例如：chet2026/cdev:20260824-111834
TAG=$(date +%Y%m%d-%H%M%S)
docker build -t chet2026/cdev:${TAG} .
docker push chet2026/cdev:${TAG}

```
## Run
```shell

# 1. 自动将当前目录路径转换为安全的容器名（例如 /home/user/my-project -> cdev-my-project）
CONTAINER_NAME="cdev-$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')"

# 2. 运行容器
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 8080:8000 \
  -v "$(pwd)":/workspace \
  --restart unless-stopped \
  chet2026/cdev:latest

```
