# VibeBox

One-line setup for a vibe-coding terminal environment.

## Installation

```bash
curl -fsSL -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/zobinHuang/vibebox/contents/setup.sh | bash
```

## What it installs

- **tmux** — session, tab, and pane management (with zellij-style keybindings)
- **Yazi** — terminal file manager
- **Claude Code** — AI coding assistant
- **vbox** — command to manage tmux sessions
- **Vibe music** *(opt-in)* — ambient internet radio that reacts to each pane's activity

## Usage

```bash
vbox new <name>            # Create a new session
vbox new --vibe <name>     # Create a session with ambient vibe music
vbox attach <name>         # Attach to existing session
vbox ls                    # List all sessions
vbox exit                  # Kill current session
```

## Keybindings

### Tabs (`Ctrl+t` then...)

| Key | Action |
|---|---|
| `n` | New tab |
| `r` | Rename tab |
| `Left` / `Right` or `h` / `l` | Switch tab |
| `1`–`9` | Jump to tab by number |
| `x` | Close tab |

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

### Yazi (file manager)

| Key | Action |
|---|---|
| `cr` | Copy relative path to clipboard |
| `s` | Search file contents |

Sessions are named `<username>-<name>`. Re-running the install script is safe — it always updates configs to the latest version.

## Vibe mode

Each tmux pane gets an ambient internet-radio soundtrack that reacts to what it's doing. Idle pane → chill jazz. Running command or thinking Claude → tenser music, with intensity scaling on the process tree's CPU/memory load. Switching panes crossfades the radio dial (~3s, equal-power) to the new pane's vibe.

Vibe mode is **opt-in**. Existing `vbox new <name>` behavior is unchanged.

### Enabling

```bash
# per-session, ad-hoc:
vbox new --vibe <name>

# or set the env var (handy in your rc):
VBOX_VIBE=1 vbox new <name>
```

To wire shell hooks (so plain shell commands flip the pane to "running"), reinstall vibebox once with the opt-in:

```bash
VBOX_VIBE=1 curl -fsSL -H 'Accept: application/vnd.github.v3.raw' \
  https://api.github.com/repos/zobinHuang/vibebox/contents/setup.sh | bash
```

That adds a single `source ~/.config/vibebox/shell-hooks.sh` line to your `~/.bashrc` / `~/.zshrc`. The sourced file self-gates on `@vibe-active-slot`, so non-vibe sessions stay no-op.

### Keybindings (`Ctrl+t` then…)

| Key | Action |
|---|---|
| `m` | Toggle global mute (fade current slot to 0 / restore) |
| `M` | Kill mpv processes for this session (re-enable with `vbox new --vibe`) |
| `]` | Bump intensity up one tier for 60s |
| `[` | Bump intensity down one tier for 60s |

The status bar shows the current vibe: 🌿 chill, 🎷 mellow, 🔥 intense, 🔇 muted/offline.

### Customizing stations

Default stations are SomaFM streams (free, listener-supported — donate at <https://somafm.com/support/>). Edit `~/.config/vibebox/stations.conf` to remap. Format:

```
<min_intensity> <max_intensity> <stream_url> <label words…>
```

Read top-to-bottom, first matching range wins. Anything `mpv` can play (HTTP/HTTPS, m3u, plain audio files, local paths) is fair game.

```
0.0 0.3 https://ice2.somafm.com/groovesalad-128-mp3   Groove Salad
0.3 0.6 https://ice2.somafm.com/indiepop-128-mp3      Indie Pop Rocks
0.6 1.0 https://ice2.somafm.com/metal-128-mp3         Metal Detector
```

Re-running setup.sh preserves your edits.

### Disabling

Three options, in order of fluffiness:

1. Just don't pass `--vibe`. Existing sessions never start mpv.
2. Inside a vibe session, `Ctrl+t` then `M` kills the mpv pair until next `vbox new --vibe`.
3. To remove the shell-hooks rc line, run setup.sh again *without* `VBOX_VIBE=1` — it strips the line idempotently.

### Bandwidth note

The default stations are 128 kbps MP3 streams (~1 MB/min). At any moment one slot is audible and the other is briefly active during a 3-second crossfade, so peak transient bandwidth is ~2× steady-state. If you're on a metered connection or in a quiet office, mute with `Ctrl+t m` or pick lighter URLs in `stations.conf` — SomaFM offers AAC streams down to 24 kbps.

### Files

```
~/.local/bin/vbox-music          dispatcher
~/.local/bin/vbox-mpv-ipc        JSON command shim over mpv's IPC socket
~/.config/vibebox/stations.conf  intensity → station map (user-editable)
~/.config/vibebox/tmux-vibe.conf hooks, status segment, keybindings
~/.config/vibebox/shell-hooks.sh preexec/precmd/DEBUG hooks
~/.config/vibebox/claude-hooks.json snippet merged into ~/.claude/settings.json
~/.cache/vibebox/music.log       diagnostic log
```
