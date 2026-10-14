#!/usr/bin/env bash
set -e

# 1. 定义镜像名称
IMAGE_NAME="chet2026/cdev"
TAG=$(date +%Y%m%d-%H%M%S)

echo "------------------------------------------------"
echo "🔨 正在使用 Buildx 构建多架构镜像 (amd64 / arm64)..."
echo "   镜像标签: ${IMAGE_NAME}:${TAG} 和 ${IMAGE_NAME}:latest"
echo "------------------------------------------------"

# 2. 创建或使用支持多架构的 buildx builder
BUILDER_NAME="cdev-builder"
if ! docker buildx inspect "${BUILDER_NAME}" >/dev/null 2>&1; then
    docker buildx create --name "${BUILDER_NAME}" --use >/dev/null 2>&1 || true
fi
docker buildx use "${BUILDER_NAME}" 2>/dev/null || true

# 3. 构建多架构镜像并推送到 Docker Hub
echo "🚀 开始构建并推送多架构镜像..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "${IMAGE_NAME}:${TAG}" \
  -t "${IMAGE_NAME}:latest" \
  --push \
  .

echo "------------------------------------------------"
echo "✅ 多架构镜像构建并推送成功！"
echo "   版本标签: ${IMAGE_NAME}:${TAG}"
echo "   通用标签: ${IMAGE_NAME}:latest"
echo "   支持架构: linux/amd64, linux/arm64 (原生支持 Apple Silicon M系列)"
echo "------------------------------------------------"

