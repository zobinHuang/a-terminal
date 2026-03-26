# VibeBox

One-line setup for a vibe-coding terminal environment.

## Installation

```bash
curl -fsSL -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/zobinHuang/vibebox/main/setup.sh | bash
```

## What it installs

- **tmux** — session, tab, and pane management (with custom keybindings)
- **Yazi** — terminal file manager
- **Claude Code** — AI coding assistant
- **vbox** — command to manage tmux sessions

## Usage

```bash
vbox new <name>        # Create and attach to a new session
vbox attach <name>     # Attach to an existing session
vbox ls                # List all vbox sessions
vbox exit              # Kill current session
```

## Keybindings

### Tabs (windows)

| Action | Keybinding |
|---|---|
| New tab | `Alt+t` |
| Rename tab | `Alt+r` |
| Switch tab left/right | `Alt+Left` / `Alt+Right` |
| Close pane/tab | `Alt+w` |

### Panes

| Action | Keybinding |
|---|---|
| Split vertical | `Alt+\` |
| Split horizontal | `Alt+-` |
| Navigate panes | `Alt+Up/Down` or `Alt+h/j/k/l` |

### Yazi (file manager)

| Action | Keybinding |
|---|---|
| Copy relative path | `cr` |
| Search file contents | `s` |

Sessions are named `<username>-<name>`. Re-running the install script is safe — it always updates configs to the latest version.
