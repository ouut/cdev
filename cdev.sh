#!/usr/bin/env bash
set -e

echo "------------------------------------------------"
echo "🚀 Initializing Cdev Development Environment..."
echo "------------------------------------------------"

# 1. Ensure systemd linger is enabled (prevents container termination when closing the terminal)
if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$(whoami)" 2>/dev/null || {
        echo "🔒 Administrator privileges required to enable background lingering. Please enter your sudo password:"
        sudo loginctl enable-linger "$(whoami)"
    }
fi

# 2. Automatically generate a safe container name from the current directory
CONTAINER_NAME="cdev-$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_.-]/-/g')"

# 3. Clean up any existing container with the same name to avoid naming conflicts
# docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# 4. Run the container (uses the built-in CMD from the Dockerfile; data persists in the current directory)
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 8080:8000 \
  -v "$(pwd)":/workspace \
  --restart unless-stopped \
  chet2026/cdev:latest

echo "------------------------------------------------"
echo "✅ Cdev started successfully!"
echo "📂 Current Workspace: $(pwd)"
echo "🌐 Access URL (Click to open directly):"
echo "   \033[4mhttp://localhost:8080/?folder=/workspace\033[0m"
echo "------------------------------------------------"
