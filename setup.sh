#!/usr/bin/env bash
set -euo pipefail

# ─── colors ───────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[✗]${NC} $*"; }

# ─── install via conda (into dedicated vibebox env) ─────────────────
VBOX_ENV="vibebox"
install_pkg() {
  if ! command -v conda &>/dev/null; then
    err "conda not found. Please install Miniconda or Anaconda first."
    return 1
  fi
  # create env if it doesn't exist
  if ! conda env list 2>/dev/null | grep -q "^${VBOX_ENV} "; then
    conda create -y -n "$VBOX_ENV" -c conda-forge --no-default-packages < /dev/null 2>&1 || return 1
  fi
  conda install -y -n "$VBOX_ENV" -c conda-forge "$@" < /dev/null 2>&1 || return 1
}

# helper: resolve path to a binary installed in the vibebox env
vbox_bin() {
  local CONDA_PREFIX
  CONDA_PREFIX="$(conda info --envs 2>/dev/null | grep "^${VBOX_ENV} " | awk '{print $NF}')"
  echo "${CONDA_PREFIX}/bin/$1"
}

# ─── fetch a file from this repo's raw API (avoids CDN cache) ────────
VBOX_REPO_API="https://api.github.com/repos/zobinHuang/vibebox/contents"
vbox_fetch() {
  # vbox_fetch <repo-path> <local-dest>
  # On failure, captures curl's stderr + http status into the global
  # VBOX_FETCH_ERR so the caller can surface it to the user.
  local src="$1" dest="$2" curl_err http_code curl_rc
  VBOX_FETCH_ERR=""
  curl_err="$(mktemp)"
  http_code="$(curl -sSL -w '%{http_code}' \
                -H 'Accept: application/vnd.github.v3.raw' \
                "${VBOX_REPO_API}/${src}" \
                -o "$dest" 2>"$curl_err")"
  curl_rc=$?
  if [ "$curl_rc" -ne 0 ]; then
    VBOX_FETCH_ERR="curl exit=$curl_rc: $(tr '\n' ' ' <"$curl_err")"
    rm -f "$curl_err"
    return 1
  fi
  rm -f "$curl_err"
  case "$http_code" in
    2??) return 0 ;;
    *)
      # On non-2xx the body was written to $dest — peek at it for the
      # actual GitHub error (rate-limit, 404, etc). Truncate so we don't
      # spam the terminal with a full HTML page.
      VBOX_FETCH_ERR="HTTP $http_code from ${VBOX_REPO_API}/${src} — $(head -c 200 "$dest" 2>/dev/null | tr '\n' ' ')"
      rm -f "$dest"
      return 1
      ;;
  esac
}

# When running `bash setup.sh` from a clone, prefer the local file. When
# running via `curl|bash`, BASH_SOURCE points to /dev/fd/N or main and the
# sibling check fails, so we fall back to fetching from GitHub.
VBOX_SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  VBOX_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
fi
VBOX_CFG_DIR="$HOME/.config/vibebox"
VBOX_INSTALL_ERR=""

vbox_install_file() {
  # vbox_install_file <repo-path> <dest>
  # On failure, sets VBOX_INSTALL_ERR with a human-readable reason.
  local src="$1" dest="$2"
  VBOX_INSTALL_ERR=""
  if [ -n "$VBOX_SCRIPT_DIR" ] && [ -f "$VBOX_SCRIPT_DIR/$src" ]; then
    if ! cp "$VBOX_SCRIPT_DIR/$src" "$dest" 2>/dev/null; then
      VBOX_INSTALL_ERR="cp $VBOX_SCRIPT_DIR/$src -> $dest failed"
      return 1
    fi
    return 0
  fi
  if vbox_fetch "$src" "$dest"; then
    return 0
  fi
  VBOX_INSTALL_ERR="$VBOX_FETCH_ERR"
  return 1
}

# ──────────────────────────────────────────────────────────────────────
COMMIT_HASH="$(curl -fsSL https://api.github.com/repos/zobinHuang/vibebox/commits/main 2>/dev/null | grep -m1 '"sha"' | cut -d'"' -f4 | cut -c1-7)" || true
COMMIT_HASH="${COMMIT_HASH:-unknown}"

echo ""
echo "══════════════════════════════════════════════════"
echo "  VibeBox Setup"
echo "  commit: $COMMIT_HASH"
echo "══════════════════════════════════════════════════"

# ─── 1. tmux ─────────────────────────────────────────────────────────
echo ""
echo "── tmux ─────────────────────────────────────────"

if command -v tmux &>/dev/null; then
  info "tmux already installed ($(tmux -V))"
else
  err "tmux not found. Please install tmux first (e.g. sudo apt install tmux)"
fi

# ─── 2. mpv + socat (vibe music engine) ──────────────────────────────
echo ""
echo "── mpv & socat (vibe music) ─────────────────────"

# mpv
if command -v mpv &>/dev/null; then
  info "mpv already installed ($(mpv --version 2>/dev/null | head -1 | cut -d' ' -f1-2))"
elif [ -x "$(vbox_bin mpv)" ]; then
  info "mpv already installed in vibebox env"
else
  warn "Installing mpv …"
  if install_pkg mpv; then
    info "mpv installed"
  else
    warn "mpv install failed — vibe music will be unavailable. Install manually: conda install -n vibebox -c conda-forge mpv"
  fi
fi

# socat (used by vbox-music to talk to mpv's IPC socket)
if command -v socat &>/dev/null; then
  info "socat already installed"
elif [ -x "$(vbox_bin socat)" ]; then
  info "socat already installed in vibebox env"
else
  warn "Installing socat …"
  if install_pkg socat; then
    info "socat installed"
  else
    warn "socat install failed — vibe music will be unavailable. Install manually: conda install -n vibebox -c conda-forge socat"
  fi
fi

# jq (used to safely merge Claude Code hooks into ~/.claude/settings.json)
if command -v jq &>/dev/null; then
  info "jq already installed"
elif [ -x "$(vbox_bin jq)" ]; then
  info "jq already installed in vibebox env"
else
  warn "Installing jq …"
  if install_pkg jq; then
    info "jq installed"
  else
    warn "jq install failed — Claude Code hooks merge will be skipped. Install manually if you want vibe state from claude: conda install -n vibebox -c conda-forge jq"
  fi
fi

# ─── patch tmux config ────────────────────────────────────────────────
TMUX_CONF="$HOME/.tmux.conf"

cat > "$TMUX_CONF" <<'TMUX'
# [vibebox] patched

# ─── clipboard & input ───────────────────────────────────────────────
set -g default-terminal "xterm-256color"
set -g set-clipboard on
if-shell "tmux -V | awk '{if($2+0 >= 3.3) exit 0; else exit 1}'" "set -g allow-passthrough on" ""
set -g mouse on
set -g mode-keys vi

# ─── mouse/vi copy → pipe through osc52-copy for clipboard ──────────
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "~/.local/bin/osc52-copy"
bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "~/.local/bin/osc52-copy"
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "~/.local/bin/osc52-copy"

# ─── smart navigation: Alt + arrows (pane first, then tab) ──────────
bind -n M-Left if-shell -F "#{pane_at_left}" "previous-window" "select-pane -L"
bind -n M-Right if-shell -F "#{pane_at_right}" "next-window" "select-pane -R"
bind -n M-Up if-shell -F "#{pane_at_top}" "" "select-pane -U"
bind -n M-Down if-shell -F "#{pane_at_bottom}" "" "select-pane -D"

# ─── tab mode: Ctrl+t → action ───────────────────────────────────────
bind -n C-t switch-client -T tab_mode
bind -T tab_mode n new-window -c "#{pane_current_path}"
bind -T tab_mode r command-prompt -I "#W" "rename-window '%%'"
bind -T tab_mode x kill-window
bind -T tab_mode Left previous-window
bind -T tab_mode Right next-window
bind -T tab_mode h previous-window
bind -T tab_mode l next-window
bind -T tab_mode 1 select-window -t 1
bind -T tab_mode 2 select-window -t 2
bind -T tab_mode 3 select-window -t 3
bind -T tab_mode 4 select-window -t 4
bind -T tab_mode 5 select-window -t 5
bind -T tab_mode 6 select-window -t 6
bind -T tab_mode 7 select-window -t 7
bind -T tab_mode 8 select-window -t 8
bind -T tab_mode 9 select-window -t 9
# Nested-tmux passthrough: Ctrl+t Ctrl+t forwards Ctrl+t to the pane.
# Use case: `vbox` running locally with an inner `vbox` over SSH.
bind -T tab_mode C-t send-keys C-t
# Alt+arrows aren't chord triggers, so the outer always intercepts them.
# `Ctrl+t Alt+<dir>` forwards the chord to the pane for quick inner-side
# pane/window navigation. For longer stretches of inner-side work, use
# F12 to fully disable outer bindings (see below).
bind -T tab_mode M-Left  send-keys M-Left
bind -T tab_mode M-Right send-keys M-Right
bind -T tab_mode M-Up    send-keys M-Up
bind -T tab_mode M-Down  send-keys M-Down

# ─── pane mode: Ctrl+p → action ─────────────────────────────────────
bind -n C-p switch-client -T pane_mode
bind -T pane_mode d split-window -v -c "#{pane_current_path}"
bind -T pane_mode n split-window -h -c "#{pane_current_path}"
bind -T pane_mode x kill-pane
bind -T pane_mode Left select-pane -L
bind -T pane_mode Right select-pane -R
bind -T pane_mode Up select-pane -U
bind -T pane_mode Down select-pane -D
bind -T pane_mode h select-pane -L
bind -T pane_mode j select-pane -D
bind -T pane_mode k select-pane -U
bind -T pane_mode l select-pane -R
bind -T pane_mode z resize-pane -Z
# Nested passthrough — Ctrl+p Ctrl+p forwards Ctrl+p
bind -T pane_mode C-p send-keys C-p

# ─── resize mode: Ctrl+n → h/j/k/l (repeatable) ────────────────────
bind -n C-n switch-client -T resize_mode
bind -r -T resize_mode h resize-pane -L 2
bind -r -T resize_mode j resize-pane -D 2
bind -r -T resize_mode k resize-pane -U 2
bind -r -T resize_mode l resize-pane -R 2
bind -r -T resize_mode Left resize-pane -L 2
bind -r -T resize_mode Right resize-pane -R 2
bind -r -T resize_mode Up resize-pane -U 2
bind -r -T resize_mode Down resize-pane -D 2
# Nested passthrough — Ctrl+n Ctrl+n forwards Ctrl+n
bind -T resize_mode C-n send-keys C-n

# ─── F12: nested-tmux passthrough toggle ─────────────────────────────
# When you're inside an inner tmux (e.g. SSH'd into a remote vbox),
# the outer tmux intercepts Ctrl+t/p/n and Alt+arrows. F12 swaps the
# active key-table to "off" so every outer binding becomes inert and
# keystrokes pass straight through to the pane (= the inner tmux).
# Press F12 again to restore the outer's bindings. status-left shows
# `[PASSTHRU]` while in off-mode so you don't forget you're in it.
bind -T root F12 set key-table off \; refresh-client -S
bind -T off  F12 set -u key-table  \; refresh-client -S

# ─── keep custom tab names ───────────────────────────────────────────
setw -g automatic-rename off
set -g allow-rename off

# ─── windows start at 1 (not 0) ─────────────────────────────────────
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# ─── status bar (tab bar) ────────────────────────────────────────────
set -g status-position bottom
set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
set -g status-left-length 80
# `#h` is tmux's short hostname (no domain). A bright yellow [PASSTHRU]
# block appears when F12 has switched the active key-table to "off"
# (nested-tmux passthrough mode).
set -g status-left "#[bg=#cba6f7,fg=#1e1e2e,bold] VibeBox [#h] #[default] #[bg=#89b4fa,fg=#1e1e2e,bold] ◆ #S #[default]#{?#{==:#{client_key_table},off}, #[bg=#f9e2af#,fg=#1e1e2e#,bold] PASSTHRU #[default],} "
set -g status-right-length 140
# vbox-music tick is short-circuit-cheap (<5ms) when there's no @vibe-active-slot
# on the session, so calling it unconditionally costs almost nothing for non-vibe
# users — and avoids tmux's nested-format-expansion gotchas around #{@option}.
# When vibe is active, the tick output is roughly:
#     🌿 cruising · Groove Salad ♫ <26-char scrolling song marquee>
# which is why status-right-length is generous here.
set -g status-right "#(vbox-music tick 2>/dev/null)#[default] #[fg=#a6adc8]│ %Y-%m-%d %H:%M "
set -g status-interval 1
setw -g window-status-format "#[fg=#a6adc8] #I:#W "
setw -g window-status-current-format "#[bg=#45475a,fg=#89b4fa,bold] ▸ #I:#W "
setw -g window-status-separator ""

# ─── pane borders ────────────────────────────────────────────────────
set -g pane-border-style "fg=#45475a"
set -g pane-active-border-style "fg=#89b4fa"

# ─── vibe music (sourced if installed; silently skipped otherwise) ──
source-file -q ~/.config/vibebox/tmux-vibe.conf
TMUX
info "Patched .tmux.conf (tabs, panes, Alt keybindings, status bar)"

# ─── install OSC 52 clipboard helper ─────────────────────────────────
mkdir -p "$HOME/.local/bin"
OSC52_BIN="$HOME/.local/bin/osc52-copy"
printf '%s' '#!/usr/bin/env bash
data=$(base64 | tr -d '"'"'\n'"'"')
PANE_TTY=$(tmux display-message -p "#{pane_tty}" 2>/dev/null || true)
if [ -n "$PANE_TTY" ] && [ -e "$PANE_TTY" ]; then
  printf '"'"'\033]52;c;%s\a'"'"' "$data" > "$PANE_TTY"
else
  printf '"'"'\033]52;c;%s\a'"'"' "$data" > /dev/tty
fi
' > "$OSC52_BIN"
chmod +x "$OSC52_BIN"
info "Installed osc52-copy helper"

# ─── patch vimrc ──────────────────────────────────────────────────────
VIMRC="$HOME/.vimrc"

cat > "$VIMRC" <<'VIM'
" [vibebox] patched
syntax on
set number
VIM
info "Patched .vimrc (line numbers + syntax highlighting)"

# ─── merge vbox-music hooks into ~/.claude/settings.json ─────────────
# Claude Code itself isn't installed by this script (install it however
# you prefer — https://claude.ai/install or your package manager). We
# still write the hooks into ~/.claude/settings.json so vibe music
# transitions correctly the moment you do install Claude Code.
# Idempotent: a "vbox-music set-state" string acts as the marker. Existing
# user hooks under PreToolUse / Stop / SubagentStop are preserved by jq's
# array-concat. If jq isn't available we leave settings.json alone and tell
# the user how to add it manually.
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
mkdir -p "$CLAUDE_DIR"

if [ -f "$CLAUDE_SETTINGS" ] && grep -q "vbox-music set-state" "$CLAUDE_SETTINGS" 2>/dev/null; then
  info "Claude Code vibe hooks already merged"
elif command -v jq &>/dev/null; then
  CLAUDE_TMP="$(mktemp)"
  if [ -f "$CLAUDE_SETTINGS" ]; then
    cp "$CLAUDE_SETTINGS" "${CLAUDE_SETTINGS}.bak.$(date +%s)" 2>/dev/null || true
    INPUT="$CLAUDE_SETTINGS"
  else
    printf '{}' > "$CLAUDE_TMP.in"
    INPUT="$CLAUDE_TMP.in"
  fi
  if jq '
    .hooks //= {} |
    .hooks.PreToolUse   = ((.hooks.PreToolUse   // []) + [{matcher: ".*", hooks: [{type: "command", command: "vbox-music set-state \"$TMUX_PANE\" thinking"}]}]) |
    .hooks.Stop         = ((.hooks.Stop         // []) + [{matcher: ".*", hooks: [{type: "command", command: "vbox-music set-state \"$TMUX_PANE\" idle"}]}]) |
    .hooks.SubagentStop = ((.hooks.SubagentStop // []) + [{matcher: ".*", hooks: [{type: "command", command: "vbox-music set-state \"$TMUX_PANE\" idle"}]}])
  ' "$INPUT" > "$CLAUDE_TMP" 2>/dev/null && [ -s "$CLAUDE_TMP" ]; then
    mv "$CLAUDE_TMP" "$CLAUDE_SETTINGS"
    rm -f "${CLAUDE_TMP}.in"
    info "Merged vibe hooks into $CLAUDE_SETTINGS"
  else
    rm -f "$CLAUDE_TMP" "${CLAUDE_TMP}.in"
    err "Failed to merge Claude Code hooks (jq error). Existing settings unchanged."
  fi
else
  warn "jq not available — skipping Claude Code hooks merge."
  warn "  To wire claude → vibe music manually, copy hooks from ~/.config/vibebox/claude-hooks.json"
  warn "  into the \"hooks\" object of $CLAUDE_SETTINGS"
fi

# stash a copy of the snippet for users to inspect / merge by hand
vbox_install_file config/claude-hooks.json "$VBOX_CFG_DIR/claude-hooks.json" 2>/dev/null || true

# ─── 3b. vbox-music (vibe music engine) ─────────────────────────────
echo ""
echo "── vbox-music (vibe music) ───────────────────────"

mkdir -p "$VBOX_CFG_DIR" "$HOME/.local/bin" "$HOME/.cache/vibebox"

# bin scripts — always overwrite so re-running setup.sh upgrades them
_vbox_install_or_fail() {
  # _vbox_install_or_fail <repo-path> <dest> <label>
  if vbox_install_file "$1" "$2"; then
    return 0
  fi
  err "Failed to install $3 — ${VBOX_INSTALL_ERR:-<no error captured>}"
  return 1
}

if _vbox_install_or_fail bin/vbox-music     "$HOME/.local/bin/vbox-music"     "vbox-music" \
   && _vbox_install_or_fail bin/vbox-mpv-ipc "$HOME/.local/bin/vbox-mpv-ipc" "vbox-mpv-ipc" \
   && _vbox_install_or_fail bin/vbox-uptime  "$HOME/.local/bin/vbox-uptime"  "vbox-uptime"; then
  chmod +x "$HOME/.local/bin/vbox-music" "$HOME/.local/bin/vbox-mpv-ipc" "$HOME/.local/bin/vbox-uptime"
  info "Installed vbox-music + vbox-mpv-ipc + vbox-uptime"
fi

# tmux-vibe.conf — always overwrite (sourced by main .tmux.conf)
if _vbox_install_or_fail config/tmux-vibe.conf "$VBOX_CFG_DIR/tmux-vibe.conf" "tmux-vibe.conf"; then
  info "Installed tmux-vibe.conf"
fi

# shell-hooks.sh — installed always; rc source line only when VBOX_VIBE=1
if _vbox_install_or_fail config/shell-hooks.sh "$VBOX_CFG_DIR/shell-hooks.sh" "shell-hooks.sh"; then
  info "Installed shell-hooks.sh"
fi

# stations.conf — preserve user customizations on re-install
if [ -f "$VBOX_CFG_DIR/stations.conf" ]; then
  info "stations.conf already exists (preserving user edits)"
else
  if _vbox_install_or_fail config/stations.conf "$VBOX_CFG_DIR/stations.conf" "stations.conf"; then
    info "Installed default stations.conf"
  fi
fi

# vibes.conf — same: preserve user-defined tier labels / glyphs / thresholds
if [ -f "$VBOX_CFG_DIR/vibes.conf" ]; then
  info "vibes.conf already exists (preserving user edits)"
else
  if _vbox_install_or_fail config/vibes.conf "$VBOX_CFG_DIR/vibes.conf" "vibes.conf"; then
    info "Installed default vibes.conf"
  fi
fi

# ─── 4. install vbox command ─────────────────────────────────────
echo ""
echo "── vbox command ──────────────────────────────"

VBOX_BIN="$HOME/.local/bin/vbox"

mkdir -p "$HOME/.local/bin"
cat > "$VBOX_BIN" <<'VBOX_SCRIPT'
#!/usr/bin/env bash
# [vibebox]
set -euo pipefail

usage() {
  echo "Usage:"
  echo "  vbox new [--vibe] <session-name>   Create and attach to a new vbox session"
  echo "  vbox attach <name>                 Attach to an existing session"
  echo "  vbox ls                            List all vbox sessions"
  echo "  vbox kill <name>                   Kill a session by name"
  echo "  vbox exit                          Kill current session"
  echo ""
  echo "  --vibe : start the ambient vibe-music engine for the new session"
  echo "           (or set VBOX_VIBE=1 in the environment)"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

CMD="$1"
shift

case "$CMD" in
  exit)
    if [ -n "${TMUX:-}" ]; then
      command -v vbox-music >/dev/null 2>&1 && vbox-music stop 2>/dev/null || true
      tmux kill-session
    else
      echo "Not inside a tmux session."
    fi
    ;;
  attach)
    if [ $# -lt 1 ]; then
      echo "Usage: vbox attach <session-name>"
      exit 1
    fi
    SESSION_NAME="$(whoami)-$1"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      tmux attach-session -t "$SESSION_NAME"
    else
      echo "Session '$SESSION_NAME' not found."
      echo "Available sessions:"
      tmux list-sessions 2>/dev/null || echo "  (none)"
      exit 1
    fi
    ;;
  ls)
    PREFIX="$(whoami)-"
    FOUND=0
    NOW=$(date +%s)
    while IFS="|" read -r SNAME CREATED; do
      if [[ "$SNAME" == "$PREFIX"* ]]; then
        SHORT="${SNAME#$PREFIX}"
        ELAPSED=$(( NOW - CREATED ))
        DAYS=$(( ELAPSED / 86400 ))
        HOURS=$(( (ELAPSED % 86400) / 3600 ))
        MINS=$(( (ELAPSED % 3600) / 60 ))
        if [ "$DAYS" -gt 0 ]; then
          DUR="${DAYS}d ${HOURS}h"
        elif [ "$HOURS" -gt 0 ]; then
          DUR="${HOURS}h ${MINS}m"
        else
          DUR="${MINS}m"
        fi
        CREATED_FMT=$(date -d "@$CREATED" "+%Y-%m-%d %H:%M" 2>/dev/null || date -r "$CREATED" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "unknown")
        printf "  %-20s created: %s  uptime: %s\n" "$SHORT" "$CREATED_FMT" "$DUR"
        FOUND=1
      fi
    done < <(tmux list-sessions -F "#{session_name}|#{session_created}" 2>/dev/null || true)
    if [ "$FOUND" -eq 0 ]; then
      echo "No vbox sessions."
    fi
    ;;
  kill)
    if [ $# -lt 1 ]; then
      echo "Usage: vbox kill <session-name>"
      exit 1
    fi
    SESSION_NAME="$(whoami)-$1"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      command -v vbox-music >/dev/null 2>&1 && vbox-music stop "$SESSION_NAME" 2>/dev/null || true
      tmux kill-session -t "$SESSION_NAME"
      echo "Killed session: $1"
    else
      echo "Session '$1' not found."
    fi
    ;;
  new)
    VIBE=0
    [ "${VBOX_VIBE:-}" = "1" ] && VIBE=1
    NAME=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --vibe)    VIBE=1; shift ;;
        --no-vibe) VIBE=0; shift ;;
        --) shift; NAME="${1:-}"; break ;;
        -*) echo "vbox new: unknown flag $1" >&2; exit 1 ;;
        *)  NAME="$1"; shift ;;
      esac
    done
    if [ -z "$NAME" ]; then
      echo "Usage: vbox new [--vibe] <session-name>"
      exit 1
    fi
    SESSION_NAME="$(whoami)-$NAME"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      echo "Session '$SESSION_NAME' already exists. Use 'vbox attach $NAME' instead."
      exit 1
    fi
    tmux new-session -d -s "$SESSION_NAME" -c "$HOME"
    if [ "$VIBE" = "1" ]; then
      if command -v vbox-music >/dev/null 2>&1; then
        vbox-music start "$SESSION_NAME" || true
      else
        echo "vbox: --vibe requested but vbox-music isn't on PATH; continuing without music." >&2
      fi
    fi
    tmux attach-session -t "$SESSION_NAME"
    ;;
  -h|--help) usage ;;
  *)         usage ;;
esac
VBOX_SCRIPT
chmod +x "$VBOX_BIN"
info "Installed vbox command to $VBOX_BIN"

# ensure ~/.local/bin and vibebox env bin are in PATH
SHELL_RC="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] && SHELL_RC="$HOME/.zshrc"
PATH_MARKER="# [vibebox] path"

# find conda env bin (try multiple methods)
VBOX_ENV_BIN=""
if command -v conda &>/dev/null; then
  CONDA_BASE="$(conda info --base 2>/dev/null || true)"
  if [ -n "$CONDA_BASE" ] && [ -d "$CONDA_BASE/envs/$VBOX_ENV/bin" ]; then
    VBOX_ENV_BIN="$CONDA_BASE/envs/$VBOX_ENV/bin"
  fi
fi

# remove old vibebox path line if exists, then write fresh.
# Brackets in PATH_MARKER are regex metacharacters; literal-match them.
sed -i.bak '/# \[vibebox\] path/,+1d' "$SHELL_RC" 2>/dev/null || true
rm -f "${SHELL_RC}.bak"

if [ -n "$VBOX_ENV_BIN" ]; then
  PATH_LINE="export PATH=\"\$HOME/.local/bin:\$PATH:${VBOX_ENV_BIN}\""
else
  PATH_LINE="export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
printf '\n%s\n%s\n' "$PATH_MARKER" "$PATH_LINE" >> "$SHELL_RC"
info "Added vibebox PATH to $(basename "$SHELL_RC")"
warn "Run 'source $SHELL_RC' or restart your shell"

# ─── opt-in: vibe-music shell hooks ───────────────────────────────────
# Append a source line for shell-hooks.sh only when VBOX_VIBE=1 was set at
# install time. The file itself self-gates on @vibe-active-slot, so non-vibe
# sessions inside an opted-in shell are still no-op.
HOOK_MARKER="# [vibebox] vibe-hooks"
HOOK_LINE="[ -f \$HOME/.config/vibebox/shell-hooks.sh ] && . \$HOME/.config/vibebox/shell-hooks.sh"
# Patch both rc files: setup.sh runs in bash but the user's login shell may
# be zsh. Strip any prior copy first (idempotent re-install / opt-out path),
# then re-add only when explicitly opted in via VBOX_VIBE=1.
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$RC" ] || continue
  # Brackets in HOOK_MARKER are regex metacharacters; literal-match them.
  sed -i.bak '/# \[vibebox\] vibe-hooks/,+1d' "$RC" 2>/dev/null || true
  rm -f "${RC}.bak"
  if [ "${VBOX_VIBE:-}" = "1" ]; then
    printf '\n%s\n%s\n' "$HOOK_MARKER" "$HOOK_LINE" >> "$RC"
    info "Wired vibe-music shell hooks into $(basename "$RC") (VBOX_VIBE=1)"
  fi
done

# ─── done ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  Setup complete!"
echo ""
echo "  Sessions:"
echo "    vbox new <name>          Create a new session"
echo "    vbox new --vibe <name>   Create a session with ambient vibe music"
echo "    vbox attach <name>       Attach to existing session"
echo "    vbox ls                  List all sessions"
echo "    vbox kill <name>         Kill a session"
echo "    vbox exit                Kill current session"
echo ""
echo "  Vibe music keys (Ctrl+t then …):"
echo "    m  toggle mute     M  kill mpv     ]  TENSE-ward    [  LOOSE-ward"
echo "    =/+ louder         -  quieter      a  release lock"
echo ""
echo "  Tabs (Ctrl+t):          Panes (Ctrl+p):"
echo "    n   new tab              d   split down"
echo "    r   rename tab           n   split right"
echo "    ←/→ switch tab           ←/→/↑/↓ navigate"
echo "    x   close tab            x   close pane"
echo "                             z   toggle fullscreen"
echo ""
echo "  Resize (Ctrl+n):  h/j/k/l or arrows (repeatable)"
echo ""
echo "══════════════════════════════════════════════════"
echo ""
