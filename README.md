# Cdev 🚀

A lightweight, persistent, and "one-click" web-based VS Code development environment powered by Docker. Designed for instant spin-ups where your code is mounted directly, and configurations (such as AI agents and extensions) are persistently managed via symbolic links (`ln`).

---

## ✨ Features

- **One-Click Deployment**: Spin up a fully configured development environment instantly via a single `curl` command.
- **Symbolic Link Persistence (`ln`)**: AI agent settings, extensions, and configurations inside the container are mapped using symlinks to ensure they survive container recreations.
- **Zero Configuration**: Opens directly into your workspace with no extra setup required.
- **Session Protection**: Automatically handles `systemd linger` to keep background tasks and servers running even after you close your terminal session.

---

## 🧠 How It Works (Architecture & Principles)

Cdev bridges the gap between local filesystem control and remote browser-based development through several core mechanisms:

1. **Official Microsoft VS Code CLI (`code serve-web`)**:
   - The Docker image runs the official VS Code CLI in web server mode. This turns VS Code into a robust web application accessible directly via your browser, offering the exact same experience as a native desktop installation.

2. **Host-Container Workspace Binding (`-v "$(pwd)":/workspace`)**:
   - When you execute the deployment script, your current host directory is mounted directly into the container as `/workspace`. Any code changes you make in the browser instantly reflect on your local host machine.

3. **Symbolic Link Persistence for AI Agents & Configurations (`ln`)**:
   - Many AI coding assistants (such as Claude Code, Codex, or custom CLI agents) store their authentication tokens, global settings, or chat histories in default hidden directories within the container's home folder (e.g., `~/.claude`, `~/.config`, or `~/.vscode`). 
   - Because ephemeral containers lose everything outside of mounted volumes, Cdev uses **symbolic links (`ln -s`)** during container startup to bridge these default paths to your persistent host-backed folder (`/workspace/.vscode-server-data`).
   - **Examples**:
     ```bash
     # 1. Persist VS Code extensions and server data
     ln -sfn /workspace/.vscode-server-data/extensions /root/.vscode/extensions

     # 2. Persist Claude Code credentials, history, or configurations
     # (Assuming Claude Code stores its data in ~/.claude or ~/.config/claude)
     mkdir -p /workspace/.vscode-server-data/claude
     ln -sfn /workspace/.vscode-server-data/claude /root/.claude

     # 3. Persist other AI CLI tool configs (e.g., Codex / OpenAI CLI tokens)
     mkdir -p /workspace/.vscode-server-data/codex
     ln -sfn /workspace/.vscode-server-data/codex /root/.codex
     ```
     This ensures that whenever an AI agent saves its login session, API configurations, or cache, it transparently writes directly into your host's project folder (`.vscode-server-data`). If you destroy the container and spin up a fresh one tomorrow, your AI agents will still be logged in and fully configured!

4. **Dynamic Naming & Multi-Project Isolation (`cdev-<dirname>`)**:
   - The script automatically converts your current folder name into a safe, normalized container name (e.g., `cdev-my-awesome-project`). This allows you to run multiple independent Cdev containers simultaneously across different projects without any port conflicts or naming collisions.

5. **Systemd Linger Protection (`loginctl enable-linger`)**:
   - In standard Linux environments, when you log out of an SSH or terminal session, `systemd` terminates all background processes associated with that user. Cdev checks and enables `systemd linger` to ensure that your background tasks, development servers, and container processes remain alive and uninterrupted.

---

## 🛠️ Quick Start

Navigate to your project directory and run the following command to deploy and start your development environment:

```bash
bash <(curl -sSL [https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/cdev.sh](https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/cdev.sh))
