FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    nodejs \
    npm \
    sudo \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH

# 根据架构下载对应的 VS Code CLI (支持 amd64/x86_64 和 arm64/aarch64)
RUN ARCH="" \
    && if [ -n "${TARGETARCH}" ]; then \
        case "${TARGETARCH}" in \
            amd64) ARCH="x64" ;; \
            arm64) ARCH="arm64" ;; \
            *) echo "Unsupported TARGETARCH: ${TARGETARCH}" && exit 1 ;; \
        esac; \
    else \
        case "$(uname -m)" in \
            x86_64) ARCH="x64" ;; \
            aarch64|arm64) ARCH="arm64" ;; \
            *) echo "Unsupported uname: $(uname -m)" && exit 1 ;; \
        esac; \
    fi \
    && ( \
        curl -fSL --http1.1 -A "Mozilla/5.0" --retry 5 --retry-delay 2 \
             "https://update.code.visualstudio.com/latest/cli-alpine-${ARCH}/stable" -o vscode_cli.tar.gz || \
        curl -fSL --http1.1 -A "Mozilla/5.0" --retry 5 --retry-delay 2 \
             "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-${ARCH}" -o vscode_cli.tar.gz \
    ) \
    && tar -xzf vscode_cli.tar.gz \
    && mv code /usr/local/bin/ \
    && rm vscode_cli.tar.gz

RUN mkdir -p /workspace/.vscode-server-data

EXPOSE 8000

WORKDIR /workspace

CMD ["code", "serve-web", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--without-connection-token", \
     "--server-data-dir", "/workspace/.vscode-server-data"]
