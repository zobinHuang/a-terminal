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

Each tmux pane gets an ambient internet-radio soundtrack that reacts to what it's doing. Idle pane → LOOSE (lo-fi / ambient). Running command or thinking Claude → RAISE or TENSE, scaling with the process tree's CPU/memory load. Switching panes crossfades the radio dial (~3s, equal-power) to the new pane's vibe.

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
| `]` | Cycle mood **up** (auto → LOOSE → RAISE → TENSE → auto) — sticky, per tab |
| `[` | Cycle mood **down** (auto → TENSE → RAISE → LOOSE → auto) — sticky, per tab |
| `a` | Release manual mood for this tab, return to auto |
| `=` / `+` | Raise vibe volume by 10 (max 100) — affects mpv only, not the OS mixer |
| `-` | Lower vibe volume by 10 (min 0) |

`[locked]` next to the tier label means the mood is pinned manually for the current tab (use `Ctrl+t a` to release). Each tab carries its own mood, so locking TENSE on tab 1 doesn't affect tab 2.

The `running …` counter is also per-tab — it resets when you create a new tab and shows uptime since that tab opened, not the session.

### Status bar

```
| LOOSE · | Vol ▂ | ♫ Distant Thunder — Foggy Path
| RAISE ✦ | Vol ▅ | ♫ Indie Anthem - Some Band
| 🔐 TENSE ✺ | Vol █ | ♫ Rifftastic Rampage
```

Three pipe-separated sections, each in its own color (Catppuccin palette):

- **vibe** (`TIER GLYPH`) — tier label from `vibes.conf`, glyph from the level-based pulse loop. Color scales with intensity level: green → sky → yellow → peach → red. A `🔐` prefix appears when the mood is pinned with `Ctrl+t ] / [`.
- **volume** (`Vol GLYPH`) — blue, volume glyph one of `▂▃▄▅▆▇█`.
- **song** (`♫ <marquee>`) — mauve note + text-coloured 26-char marquee that scrolls the current track.

- **Intensity** is a single character that loops through a level-specific sequence each tick. Higher levels add one more glyph to the loop, so the cycle gets richer as intensity climbs:
  - level 1 (0.0–0.2): `· • · • …`
  - level 2 (0.2–0.4): `· • ✦ · • ✦ …`
  - level 3 (0.4–0.6): `· • ✦ ✸ · • ✦ ✸ …`
  - level 4 (0.6–0.8): `· • ✦ ✸ ✹ · • ✦ ✸ ✹ …`
  - level 5 (0.8–1.0): `· • ✦ ✸ ✹ ✺ · • ✦ ✸ ✹ ✺ …`

  The character is hardcoded — not configurable from `vibes.conf`.
- **Volume** is one block-element glyph from a 7-step ladder — `▂` (0–16%) · `▃` (17–32%) · `▄` (33–49%) · `▅` (50–66%) · `▆` (67–82%) · `▇` (83–99%) · `█` (100%).

- Vibe levels are configurable in `~/.config/vibebox/vibes.conf` (see below). Defaults: `▂ LOOSE` (low) · `▄ RAISE` (mid) · `▆ TENSE` (high)
- 26-char marquee that scrolls the current track (mpv ICY metadata, falling back to `media-title`)
- `[locked]` is appended when you've pinned the mood manually with `Ctrl+t ] / [`
- 🔇 muted when you've muted with `Ctrl+t m`
- 📻 off-air if mpv died or the stream is unreachable

### Customizing vibe levels

`~/.config/vibebox/vibes.conf` — defines the labels, glyphs, and intensity thresholds. Format:

```
<label> <glyph> <min_intensity> <max_intensity>
```

Defaults:

```
LOOSE  ▂  0.0  0.3
RAISE  ▄  0.3  0.6
TENSE  ▆  0.6  1.0
```

Each tier's mood-override midpoint is `(min + max) / 2`. Order in the file is the cycle order for `Ctrl+t ]` (next) and `Ctrl+t [` (prev). You can rename the labels, swap the glyphs, add a fourth or fifth tier, or move the boundaries — vbox-music re-reads on every status tick. Re-running `setup.sh` preserves your edits.

### Customizing stations

Default stations are SomaFM streams (free, listener-supported — donate at <https://somafm.com/support/>). Edit `~/.config/vibebox/stations.conf` to remap. Format:

```
<min_intensity> <max_intensity> <stream_url> <label words…>
```

Read top-to-bottom, first matching range wins. Anything `mpv` can play (HTTP/HTTPS, m3u, plain audio files, local paths) is fair game.

```
0.0 0.3 https://ice2.somafm.com/groovesalad-128-mp3    Groove Salad
0.3 0.6 https://ice2.somafm.com/missioncontrol-128-mp3 Mission Control
0.6 1.0 https://ice2.somafm.com/metal-128-mp3          Metal Detector
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
~/.local/bin/vbox-music             dispatcher
~/.local/bin/vbox-mpv-ipc           JSON command shim over mpv's IPC socket
~/.local/bin/vbox-uptime            per-tab uptime helper
~/.config/vibebox/vibes.conf        tier labels, glyphs, thresholds (user-editable)
~/.config/vibebox/stations.conf     intensity → station map (user-editable)
~/.config/vibebox/tmux-vibe.conf    hooks, status segment, keybindings
~/.config/vibebox/shell-hooks.sh    preexec/precmd/DEBUG hooks
~/.config/vibebox/claude-hooks.json snippet merged into ~/.claude/settings.json
~/.cache/vibebox/music.log          diagnostic log
~/.cache/vibebox/music-stderr.log   stderr from hook-fired commands
```
