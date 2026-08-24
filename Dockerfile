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

RUN curl -sSL "https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64" -o vscode_cli.tar.gz \
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
