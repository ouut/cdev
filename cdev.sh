#!/usr/bin/env bash
set -e

echo "------------------------------------------------"
echo "🚀 Initializing Cdev Development Environment..."
echo "------------------------------------------------"

# 1. Ensure systemd linger is enabled (Linux only)
if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$(whoami)" 2>/dev/null || {
        echo "🔒 Administrator privileges required to enable background lingering. Please enter your sudo password:"
        sudo loginctl enable-linger "$(whoami)"
    }
fi

# 2. Automatically generate a safe container name from the current directory
CONTAINER_NAME="cdev-$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')"
IMAGE="chet2026/cdev:latest"

# 3. Detect container engine (Prioritize Apple native 'container' CLI on macOS, fallback to docker)
if [[ "$(uname)" == "Darwin" ]] && command -v container >/dev/null 2>&1; then
    ENGINE="apple-container"
    echo "🍏 Using Apple Silicon native container engine ('container')..."
    
    # Ensure container system service is running
    if ! container system status >/dev/null 2>&1; then
        echo "⚙️ Starting Apple container system services..."
        container system start --enable-kernel-install || true
    fi

    echo "📦 Pulling image using Apple container..."
    container image pull "${IMAGE}" 2>/dev/null || container pull "${IMAGE}"

    echo "🧹 Cleaning up any existing container with name ${CONTAINER_NAME}..."
    container rm -f "${CONTAINER_NAME}" 2>/dev/null || true

    echo "🚀 Starting container with Apple native micro-VM..."
    container run -d \
      --name "${CONTAINER_NAME}" \
      -p 8080:8000 \
      -v "$(pwd)":/workspace \
      "${IMAGE}"
elif command -v docker >/dev/null 2>&1; then
    ENGINE="docker"
    echo "🐳 Using Docker container engine..."
    
    echo "📦 Pulling image..."
    docker pull "${IMAGE}"

    echo "🧹 Cleaning up any existing container with name ${CONTAINER_NAME}..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

    echo "🚀 Starting Docker container..."
    docker run -d \
      --name "${CONTAINER_NAME}" \
      -p 8080:8000 \
      -v "$(pwd)":/workspace \
      --restart unless-stopped \
      "${IMAGE}"
else
    echo "❌ Error: Neither Apple 'container' CLI nor Docker was found!"
    echo "   Please install Apple container (https://github.com/apple/container) or Docker."
    exit 1
fi

echo "------------------------------------------------"
echo "✅ Cdev started successfully via ${ENGINE}!"
echo "📂 Current Workspace: $(pwd)"
echo "🌐 Access URL (Click to open directly):"
echo "  http://localhost:8080/?folder=/workspace "
echo "------------------------------------------------"

# Automatically open browser on macOS
if command -v open >/dev/null 2>&1; then
    open "http://localhost:8080/?folder=/workspace" 2>/dev/null || true
fi
