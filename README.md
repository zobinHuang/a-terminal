# a-terminal

One-line setup for a vibe-coding terminal environment (LazyVim + Claude Code).

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/zobinHuang/a-terminal/main/setup.sh | bash
```

## What it installs

- **Neovim** + **LazyVim** (with custom config patches)
- **Claude Code**
- Prerequisites: git, curl, ripgrep, fd, lazygit

Re-running the script is safe — it skips anything already installed and re-applies config patches idempotently.
