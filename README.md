# Cdev 🚀

## 🛠️ Quick Start

Navigate to your project directory and run the following command to deploy and start your development environment:

```bash
curl -sSL https://raw.githubusercontent.com/ouut/cdev/main/cdev.sh | bash
```

---

## ✨ Features

A lightweight, persistent, and "one-click" web-based VS Code development environment powered by Docker. Designed for instant spin-ups where your code is mounted directly, and user environments and configurations (such as AI agents, shell profiles, and extensions) are persistently managed automatically.

- **One-Click Deployment**: Spin up a fully configured development environment instantly via a single `curl` command.
- **Automatic Home Persistence**: Container `/root` is mapped and initialized to `.vscode-server-data/root`, preserving shell configs, tool settings, and AI agent sessions seamlessly.
- **Zero Configuration**: Opens directly into your workspace with no extra setup required.
- **Session Protection**: Automatically handles `systemd linger` to keep background tasks and servers running even after you close your terminal session.

---

## 🧠 How It Works (Architecture & Principles)

Cdev bridges the gap between local filesystem control and remote browser-based development through several core mechanisms:

1. **Official Microsoft VS Code CLI (`code serve-web`)**:
   - The Docker image runs the official VS Code CLI in web server mode. This turns VS Code into a robust web application accessible directly via your browser, offering the exact same experience as a native desktop installation.

2. **Host-Container Workspace Binding (`-v "$(pwd)":/workspace`)**:
   - When you execute the deployment script, your current host directory is mounted directly into the container as `/workspace`. Any code changes you make in the browser instantly reflect on your local host machine.

3. **Automatic `/root` Home Persistence (`-v "$(pwd)/.vscode-server-data/root":/root`)**:
   - Many AI coding assistants (such as Claude Code, Codex, or custom CLI agents) and developer tools store their authentication tokens, global settings, or history in default directories under the home folder (e.g., `~/.claude`, `~/.config`, `~/.bashrc`).
   - On the first run, Cdev automatically copies the container's initial `/root` files (such as shell skeletons and configurations) into `$(pwd)/.vscode-server-data/root` on the host, and mounts it into `/root`.
   - This guarantees that your shell customizations, tool settings, and AI agent login states transparently persist in `.vscode-server-data/root` across container restarts and recreations.

4. **Dynamic Naming & Multi-Project Isolation (`cdev-<dirname>`)**:
   - The script automatically converts your current folder name into a safe, normalized container name (e.g., `cdev-my-awesome-project`). This allows you to run multiple independent Cdev containers simultaneously across different projects without any port conflicts or naming collisions.

5. **Systemd Linger Protection (`loginctl enable-linger`)**:
   - In standard Linux environments, when you log out of an SSH or terminal session, `systemd` terminates all background processes associated with that user. Cdev checks and enables `systemd linger` to ensure that your background tasks, development servers, and container processes remain alive and uninterrupted.

---


