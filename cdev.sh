#!/usr/bin/env bash
# ==============================================================================
# Cdev - Universal Development Environment Launcher
# Cross-Platform Support for macOS (Apple Silicon & Intel) and Linux (x86_64 & ARM64)
# ==============================================================================
set -e

# --- 1. 配置参数与参数解析 ---
IMAGE="chet2026/cdev:latest"
DEFAULT_PORT=8080
PORT="${CDEV_PORT:-$DEFAULT_PORT}"
FORCE_RECREATE=false
ACTION="run"

for arg in "$@"; do
    case "$arg" in
        --restart|--force|-f)
            FORCE_RECREATE=true
            ;;
        stop)
            ACTION="stop"
            ;;
        status)
            ACTION="status"
            ;;
        --help|-h)
            echo "Cdev Launcher - Usage:"
            echo "  ./cdev.sh             Start or resume Cdev in the current workspace"
            echo "  ./cdev.sh --restart   Force recreation of the container"
            echo "  ./cdev.sh stop        Stop the current workspace container"
            echo "  ./cdev.sh status      Check container status"
            echo ""
            echo "Environment Variables:"
            echo "  CDEV_PORT             Port to listen on (default: 8080)"
            exit 0
            ;;
    esac
done

echo "------------------------------------------------"
echo "🚀 Initializing Cdev Development Environment..."
echo "------------------------------------------------"

# --- 2. 跨平台容器名生成 (安全兼容中文、空格、特殊字符) ---
get_dir_hash() {
    printf '%s' "$(pwd)" | (md5sum 2>/dev/null || md5 -q 2>/dev/null || shasum 2>/dev/null || echo "000000") | cut -c1-6
}

RAW_DIR_NAME="$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_.-]+/-/g' | sed -E 's/^-+|-+$//g')"
[ -z "$RAW_DIR_NAME" ] && RAW_DIR_NAME="workspace"
DIR_HASH="$(get_dir_hash)"
CONTAINER_NAME="cdev-${RAW_DIR_NAME}-${DIR_HASH}"

# --- 3. Linux 专用优化：systemd linger 保活支持 ---
if [[ "$(uname -s)" == "Linux" ]] && command -v loginctl >/dev/null 2>&1; then
    CURRENT_USER="$(whoami)"
    if ! loginctl show-user "$CURRENT_USER" 2>/dev/null | grep -q "Linger=yes"; then
        loginctl enable-linger "$CURRENT_USER" 2>/dev/null || true
    fi
fi

# --- 4. 跨平台容器引擎自适应探测 (Apple container / Docker / Podman) ---
detect_engine() {
    # 策略 A: macOS 且安装了 Apple 原生 container CLI
    if [[ "$(uname -s)" == "Darwin" ]] && command -v container >/dev/null 2>&1; then
        if container system status >/dev/null 2>&1 || container --version >/dev/null 2>&1; then
            ENGINE="apple-container"
            CMD_RUN="container"
            return 0
        fi
    fi

    # 策略 B: 标准 Docker (免 sudo)
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            ENGINE="docker"
            CMD_RUN="docker"
            return 0
        fi
        # 策略 C: Linux 下普通用户未加入 docker 组时自动尝试 sudo docker
        if [[ "$(uname -s)" == "Linux" ]] && command -v sudo >/dev/null 2>&1; then
            if sudo docker info >/dev/null 2>&1; then
                ENGINE="docker"
                CMD_RUN="sudo docker"
                return 0
            fi
        fi
    fi

    # 策略 D: Podman (Linux/macOS 常见无守护进程替代)
    if command -v podman >/dev/null 2>&1; then
        if podman info >/dev/null 2>&1; then
            ENGINE="podman"
            CMD_RUN="podman"
            return 0
        fi
    fi

    # 若检测到已安装对应命令但后台服务未运行，给出精准提示与启动尝试
    if [[ "$(uname -s)" == "Darwin" ]] && command -v container >/dev/null 2>&1; then
        echo "⚙️ Apple native 'container' service is not running. Starting services..."
        container system start --enable-kernel-install 2>/dev/null || true
        if container system status >/dev/null 2>&1; then
            ENGINE="apple-container"
            CMD_RUN="container"
            return 0
        fi
    fi

    if command -v docker >/dev/null 2>&1; then
        echo "⚠️ Docker daemon is not responding."
        if [[ "$(uname -s)" == "Darwin" ]]; then
            echo "👉 If using Docker Desktop, please ensure it is opened: open -a Docker"
            echo "👉 If using Colima, please run: colima start"
        else
            echo "👉 On Linux, please run: sudo systemctl start docker"
            echo "👉 And ensure your user is in the docker group: sudo usermod -aG docker \$USER"
        fi
        exit 1
    fi

    echo "❌ Error: No supported container engine found (Docker, Apple container, or Podman)."
    echo "   Please install Docker (https://docker.com) or Apple container (https://github.com/apple/container)."
    exit 1
}

detect_engine

# --- 5. 处理辅助命令: stop / status ---
if [ "$ACTION" = "stop" ]; then
    echo "🛑 Stopping container ${CONTAINER_NAME}..."
    $CMD_RUN stop "${CONTAINER_NAME}" 2>/dev/null || true
    echo "✅ Container stopped."
    exit 0
fi

if [ "$ACTION" = "status" ]; then
    echo "🔍 Container Status for ${CONTAINER_NAME}:"
    $CMD_RUN ps -a --filter "name=^/${CONTAINER_NAME}$" 2>/dev/null || $CMD_RUN ps -a 2>/dev/null | grep "${CONTAINER_NAME}" || echo "Not found."
    exit 0
fi

# --- 6. 容器状态检查与幂等性保证 ---
is_container_running() {
    if [ "$ENGINE" = "apple-container" ]; then
        container list 2>/dev/null | grep -q "${CONTAINER_NAME}"
    else
        $CMD_RUN ps --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
    fi
}

is_container_exists() {
    if [ "$ENGINE" = "apple-container" ]; then
        container list -a 2>/dev/null | grep -q "${CONTAINER_NAME}"
    else
        $CMD_RUN ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${CONTAINER_NAME}$"
    fi
}

# 如果容器已经在运行，且未要求强行重建
if is_container_running && [ "$FORCE_RECREATE" = false ]; then
    echo "ℹ️ Container [${CONTAINER_NAME}] is already up and running!"
    echo "------------------------------------------------"
    echo "📂 Workspace: $(pwd)"
    echo "🌐 Access URL: http://localhost:${PORT}/?folder=/workspace"
    echo "------------------------------------------------"
    echo "💡 Tip: To recreate the container, run: ./cdev.sh --restart"
    
    # 自动唤起浏览器
    if [[ "$(uname -s)" == "Darwin" ]] && command -v open >/dev/null 2>&1; then
        open "http://localhost:${PORT}/?folder=/workspace" 2>/dev/null || true
    elif command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY$WAYLAND_DISPLAY" ]; then
        xdg-open "http://localhost:${PORT}/?folder=/workspace" 2>/dev/null || true
    fi
    exit 0
fi

# 如果容器存在但处于停止状态，且未要求重建，直接拉起
if is_container_exists && [ "$FORCE_RECREATE" = false ]; then
    echo "🔄 Container exists in stopped state. Starting container [${CONTAINER_NAME}]..."
    $CMD_RUN start "${CONTAINER_NAME}"
    echo "------------------------------------------------"
    echo "✅ Cdev resumed successfully via ${ENGINE}!"
    echo "📂 Workspace: $(pwd)"
    echo "🌐 Access URL: http://localhost:${PORT}/?folder=/workspace"
    echo "------------------------------------------------"
    if [[ "$(uname -s)" == "Darwin" ]] && command -v open >/dev/null 2>&1; then
        open "http://localhost:${PORT}/?folder=/workspace" 2>/dev/null || true
    elif command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY$WAYLAND_DISPLAY" ]; then
        xdg-open "http://localhost:${PORT}/?folder=/workspace" 2>/dev/null || true
    fi
    exit 0
fi

# --- 7. 端口空闲检查与自动规避 ---
is_port_in_use() {
    local port="$1"
    if command -v lsof >/dev/null 2>&1; then
        lsof -i ":${port}" >/dev/null 2>&1
    elif command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":${port} "
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln 2>/dev/null | grep -q ":${port} "
    else
        return 1
    fi
}

ORIGINAL_PORT=$PORT
while is_port_in_use "$PORT"; do
    echo "⚠️ Port ${PORT} is currently in use."
    PORT=$((PORT + 1))
    echo "👉 Auto-shifting to next free port: ${PORT}..."
    if [ $((PORT - ORIGINAL_PORT)) -gt 10 ]; then
        echo "❌ Error: Could not find an available port in range ${ORIGINAL_PORT}-$((PORT)). Please set CDEV_PORT."
        exit 1
    fi
done

# --- 8. 镜像拉取与启动 ---
echo "📦 Pulling latest image: ${IMAGE}..."
if [ "$ENGINE" = "apple-container" ]; then
    container image pull "${IMAGE}" 2>/dev/null || container pull "${IMAGE}"
else
    $CMD_RUN pull "${IMAGE}"
fi

# 初始化持久化 /root 目录（首次运行自动从镜像提取默认配置到宿主机）
HOST_ROOT_DIR="$(pwd)/.vscode-server-data/root"
if [ ! -d "$HOST_ROOT_DIR" ] || [ -z "$(ls -A "$HOST_ROOT_DIR" 2>/dev/null)" ]; then
    echo "📦 Initializing /root configuration to host (${HOST_ROOT_DIR})..."
    mkdir -p "$HOST_ROOT_DIR"
    TEMP_CID=$($CMD_RUN create "${IMAGE}" 2>/dev/null | tail -n 1 || true)
    if [ -n "$TEMP_CID" ]; then
        $CMD_RUN cp "${TEMP_CID}:/root/." "$HOST_ROOT_DIR/" 2>/dev/null || true
        $CMD_RUN rm -f "${TEMP_CID}" >/dev/null 2>&1 || true
    fi
fi

# 清理旧同名容器
if is_container_exists; then
    echo "🧹 Removing old container instance [${CONTAINER_NAME}]..."
    $CMD_RUN rm -f "${CONTAINER_NAME}" 2>/dev/null || true
fi

echo "🚀 Starting development container..."
if [ "$ENGINE" = "apple-container" ]; then
    # Apple container 运行语法
    container run -d \
      --name "${CONTAINER_NAME}" \
      --cpus 6 \
      --memory 10g \
      -e CARGO_BUILD_JOBS=4 \
      -p "${PORT}:8000" \
      -v "$(pwd)":/workspace \
      -v "${HOST_ROOT_DIR}":/root \
      "${IMAGE}"
else
    # Docker / Podman 运行语法 (Linux/macOS 通用)
    $CMD_RUN run -d \
      --name "${CONTAINER_NAME}" \
      -p "${PORT}:8000" \
      -v "$(pwd)":/workspace \
      -v "${HOST_ROOT_DIR}":/root \
      --restart unless-stopped \
      "${IMAGE}"
fi

# --- 9. 运行成功提示与自动打开浏览器 ---
echo "------------------------------------------------"
echo "✅ Cdev started successfully via ${ENGINE}!"
echo "📂 Current Workspace: $(pwd)"
echo "🌐 Access URL (Click to open directly):"
echo "  http://localhost:${PORT}/?folder=/workspace "
echo "------------------------------------------------"

# 跨平台自动打开浏览器 (SSH/无头服务器静默跳过)
if [ -z "$SSH_CLIENT" ] && [ -z "$SSH_TTY" ] && [ -z "$SSH_CONNECTION" ]; then
    if [[ "$(uname -s)" == "Darwin" ]] && command -v open >/dev/null 2>&1; then
        open "http://localhost:${PORT}/?folder=/workspace" 2>/dev/null || true
    elif command -v xdg-open >/dev/null 2>&1 && [ -n "$DISPLAY$WAYLAND_DISPLAY" ]; then
        xdg-open "http://localhost:${PORT}/?folder=/workspace" 2>/dev/null || true
    elif command -v wslview >/dev/null 2>&1; then
        wslview "http://localhost:${PORT}/?folder=/workspace" 2>/dev/null || true
    fi
fi
