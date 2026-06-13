# VibeBox

One-line setup for a vibe-coding terminal environment.

## Installation

```bash
curl -fsSL -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/zobinHuang/vibebox/contents/setup.sh | bash
```

## What it installs

- **tmux** — session, tab, and pane management (with zellij-style keybindings)
- **vbox** — command to manage tmux sessions
- **vbox-uptime** — a per-tab "running …" uptime indicator in the status bar

The installer patches `~/.tmux.conf` and `~/.vimrc`, drops a `vbox` command and
an `osc52-copy` clipboard helper into `~/.local/bin`, and adds that directory to
your `PATH`. Re-running the script is safe — it always refreshes the configs to
the latest version.

## Usage

```bash
vbox new <name>            # Create a new session
vbox attach <name>         # Attach to existing session
vbox ls                    # List all sessions
vbox kill <name>           # Kill a session by name
vbox exit                  # Kill current session
```

Sessions are named `<username>-<name>`.

## Keybindings

### Tabs (`Ctrl+t` then...)

| Key | Action |
|---|---|
| `n` | New tab |
| `r` | Rename tab |
| `Left` / `Right` or `h` / `l` | Switch tab |
| `1`–`9` | Jump to tab by number |
| `x` | Close tab |
| `Ctrl+t` | Forward `Ctrl+t` to the inner pane (nested-tmux passthrough) |

### Panes (`Ctrl+p` then...)

| Key | Action |
|---|---|
| `d` | Split down |
| `n` | Split right |
| `Left/Right/Up/Down` or `h/j/k/l` | Navigate panes |
| `x` | Close pane |
| `z` | Toggle fullscreen (zoom) |

### Resize (`Ctrl+n` then...)

| Key | Action |
|---|---|
| `h/j/k/l` or arrows | Resize pane (repeatable) |

### Other

| Key | Action |
|---|---|
| `Alt+arrows` | Smart navigation — move between panes, then tabs at the edge |
| `F12` | Toggle nested-tmux passthrough (`[PASSTHRU]` shows in status-left) |

## Status bar

The status bar shows the hostname and session name on the left, and on the
right a per-tab uptime counter plus the date/clock:

```
 VibeBox [host]  ◆ session-name              running 5m 30s │ 2026-06-13 14:14
```

The `running …` counter is **per-tab** — it resets when you create a new tab and
shows the time elapsed since that tab opened, not since the session started.

## Files

```
~/.local/bin/vbox          session-management command
~/.local/bin/vbox-uptime   per-tab uptime helper (status bar)
~/.local/bin/osc52-copy    OSC 52 clipboard helper
~/.tmux.conf               patched tmux config
~/.vimrc                   patched vim config (line numbers + syntax)
```
