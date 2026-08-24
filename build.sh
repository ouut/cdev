#!/usr/bin/env bash
set -e

# 1. 定义镜像名称
IMAGE_NAME="chet2026/cdev"
TAG=$(date +%Y%m%d-%H%M%S)

echo "------------------------------------------------"
echo "🔨 正在构建 Docker 镜像: ${IMAGE_NAME}:${TAG} 及 latest..."
echo "------------------------------------------------"

# 2. 同时构建带时间戳的标签和 latest 标签
docker build -t "${IMAGE_NAME}:${TAG}" -t "${IMAGE_NAME}:latest" .

echo "------------------------------------------------"
echo "🚀 正在推送到 Docker Hub..."
echo "------------------------------------------------"

# 3. 推送两个标签
docker push "${IMAGE_NAME}:${TAG}"
docker push "${IMAGE_NAME}:latest"

echo "------------------------------------------------"
echo "✅ 构建并推送成功！"
echo "   版本标签: ${IMAGE_NAME}:${TAG}"
echo "   通用标签: ${IMAGE_NAME}:latest"
echo "------------------------------------------------"

