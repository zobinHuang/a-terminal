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
- **vbox-agent** — the agent bar: splits your tabs into a READY row and a BUSY
  row based on what your code agents are actually doing

The installer patches `~/.tmux.conf` and `~/.vimrc`, drops a `vbox` command and
an `osc52-copy` clipboard helper into `~/.local/bin`, adds that directory to
your `PATH`, and merges its hooks into `~/.claude/settings.json`.

## Upgrading

Re-run the same one-liner. **You do not have to close your sessions** — the
installer reloads the new config into any tmux server already running, so
sessions you have open right now pick up new keybindings, status rows and hooks
immediately. Re-running is safe to repeat; nothing accumulates.

Two things don't come along automatically:

- **Codex**, if its hook definitions changed — it tracks them by hash, so run
  `/hooks` again to re-trust. Codex tells you when this is needed; a re-run that
  writes the same bytes doesn't ask.
- **A `vbox` shell that predates the install**, only for `PATH` — run
  `source ~/.zshrc` or open a new tab.

Claude Code re-reads its hooks mid-session, so running agents need nothing.

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
| `c` | Clear a tab stuck showing an agent state |
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
| `Alt+arrows` | Smart navigation — move between panes, then across the bar at the edge |
| `F12` | Toggle nested-tmux passthrough (`[PASSTHRU]` shows in status-left) |

`Alt+arrows` walks panes until you hit an edge, then keeps going on the status
bar. Once the [agent bar](#agent-bar) is showing, the bar is two-dimensional:
left/right walk along a row and wrap, up/down cross between the READY and BUSY
rows at the same column. With no agent running, left/right are just
previous/next tab and up/down do nothing — exactly as before.

## Status bar

The status bar shows the hostname and session name on the left, and on the
right a per-tab uptime counter plus the date/clock:

```
 VibeBox [host]  ◆ session-name              running 5m 30s │ 2026-06-13 14:14
```

The `running …` counter is **per-tab** — it resets when you create a new tab and
shows the time elapsed since that tab opened, not since the session started.

## Agent bar

Once a code agent runs in any tab, the bar grows two extra rows that split your
tabs by what the agent in them is doing:

```
 READY     1:shell    2:notes  ○ 3:agent  ! 5:api
 BUSY    ▸ ● 4:kernel  ● 6:paper
 VibeBox [host]  ◆ session                     running 5m 30s │ 2026-06-13 14:14
```

| Mark | Meaning |
|---|---|
| `●` | agent is working |
| `○` | agent is idle, waiting for you |
| `!` | agent is blocked on a permission prompt |
| *(no mark, dim)* | plain tab, no agent has ever run here |
| `▸` | the tab you're currently on |

**An empty row is not shown.** With every agent working the READY row
disappears; with none working the BUSY row does. Until a code agent runs at all,
the bar is exactly the single line it has always been.

Navigate it with `Alt+arrows` — left/right along a row, up/down between rows.
See [Other](#other) above.

State comes from code-agent hooks, which the installer merges in:

| Agent | File | Busy | Idle | Blocked |
|---|---|---|---|---|
| Claude Code | `~/.claude/settings.json` | `UserPromptSubmit`, `Pre`/`PostToolUse` | `Stop`, `StopFailure`, `SessionStart` | `Notification` |
| Codex | `~/.codex/hooks.json` | `UserPromptSubmit`, `Pre`/`PostToolUse` | `Stop`, `SessionStart` | `PermissionRequest` |

Any hooks you have of your own are left alone; re-running the installer replaces
only the vibebox-owned ones, and the originals are backed up alongside with a
`.vibebox.bak` suffix.

> **Codex needs one manual step.** Codex will not run a hook until you have
> reviewed it, so after installing, open codex and run `/hooks` → *Trust all and
> continue*. Until you do, codex tabs never show up in the BUSY row. You only
> have to do this again if the hook definitions themselves change — codex tracks
> them by hash, and re-running the installer writes the same bytes.

Tab names are shown truncated to 14 characters so one long name can't swallow a
whole row.

### When a tab gets stuck

An agent killed outright — `kill -9`, a hard crash — never runs its exit hook,
and if its pane stays open no tmux hook fires either, so the tab sits in BUSY
forever. Press `Ctrl+t` then `c` to clear it.

There is deliberately no automatic recovery. The two signals that look like they
should work were both measured and both fail: the pane's foreground command is
the *shell*, not the agent, whenever the agent was launched through a wrapper
script, and a directly-launched agent has *no* child processes because tmux
execs it as the pane's own process. Either check would have silently marked live
agents as dead, which is a worse failure than the one it fixes.

A tab is tracked by its tmux pane, so an agent running inside a *nested* tmux
(you SSH'd into a remote `vbox`) is invisible to the outer bar.

## Files

```
~/.local/bin/vbox          session-management command
~/.local/bin/vbox-uptime   per-tab uptime helper (status bar)
~/.local/bin/vbox-agent    agent-state tracker (READY / BUSY rows)
~/.local/bin/osc52-copy    OSC 52 clipboard helper
~/.tmux.conf               patched tmux config
~/.vimrc                   patched vim config (line numbers + syntax)
~/.claude/settings.json    Claude Code hooks merged in
~/.codex/hooks.json        Codex hooks merged in (needs /hooks to trust)
```
