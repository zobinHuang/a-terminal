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

# ─── detect package manager ──────────────────────────────────────────
install_pkg() {
  if command -v brew &>/dev/null; then
    brew install "$@"
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$@"
  else
    err "No supported package manager found. Please install manually: $*"
    return 1
  fi
}

# ─── 1. prerequisites ────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  Terminal Vibe-Coding Setup"
echo "══════════════════════════════════════════════════"
echo ""

DEPS=(git curl ripgrep fd lazygit)
# map tool names to the binary names used for checking
declare -A BIN_MAP=(
  [git]=git
  [curl]=curl
  [ripgrep]=rg
  [fd]=fd
  [lazygit]=lazygit
)

for dep in "${DEPS[@]}"; do
  bin="${BIN_MAP[$dep]}"
  if command -v "$bin" &>/dev/null; then
    info "$dep already installed"
  else
    warn "Installing $dep …"
    install_pkg "$dep"
  fi
done

# ─── 2. neovim ────────────────────────────────────────────────────────
echo ""
echo "── Neovim ─────────────────────────────────────────"

if command -v nvim &>/dev/null; then
  info "Neovim already installed ($(nvim --version | head -1))"
else
  warn "Installing Neovim …"
  install_pkg neovim
fi

# ─── 3. lazyvim ───────────────────────────────────────────────────────
echo ""
echo "── LazyVim ────────────────────────────────────────"

NVIM_CONFIG="$HOME/.config/nvim"

if [ -d "$NVIM_CONFIG" ] && [ -f "$NVIM_CONFIG/lua/config/lazy.lua" ]; then
  info "LazyVim already installed at $NVIM_CONFIG"
else
  warn "Installing LazyVim …"

  # backup existing config if present
  if [ -d "$NVIM_CONFIG" ]; then
    BACKUP="$NVIM_CONFIG.bak.$(date +%s)"
    warn "Backing up existing config to $BACKUP"
    mv "$NVIM_CONFIG" "$BACKUP"
  fi

  # backup related data dirs
  for d in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
    if [ -d "$d" ]; then
      mv "$d" "${d}.bak.$(date +%s)"
    fi
  done

  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
  # remove starter .git so user can track their own config
  rm -rf "$NVIM_CONFIG/.git"
  info "LazyVim installed"
fi

# ─── 4. patch lazyvim config ─────────────────────────────────────────
echo ""
echo "── Patching LazyVim config ──────────────────────"

# --- options.lua ---
OPTIONS_FILE="$NVIM_CONFIG/lua/config/options.lua"
OPTIONS_MARKER="-- [a-terminal] patched"

if grep -qF "$OPTIONS_MARKER" "$OPTIONS_FILE" 2>/dev/null; then
  info "options.lua already patched"
else
  cat >> "$OPTIONS_FILE" <<'LUA'

-- [a-terminal] patched
-- disable neovim 0.11+ terminal capability query to prevent iterm2 text leakage.
require("vim.termcap").query = function() end

-- map single esc key to exit terminal mode immediately.
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
LUA
  info "Patched options.lua"
fi

# --- plugins/custom.lua ---
CUSTOM_PLUGIN="$NVIM_CONFIG/lua/plugins/custom.lua"

if [ -f "$CUSTOM_PLUGIN" ] && grep -qF "width = 30" "$CUSTOM_PLUGIN" 2>/dev/null; then
  info "custom.lua already patched"
else
  mkdir -p "$(dirname "$CUSTOM_PLUGIN")"
  cat > "$CUSTOM_PLUGIN" <<'LUA'
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        -- decrease the default width of the neo-tree window to 30.
        width = 30,
      },
    },
  },
}
LUA
  info "Patched plugins/custom.lua"
fi

# ─── 5. claude code ──────────────────────────────────────────────────
echo ""
echo "── Claude Code ────────────────────────────────────"

if command -v claude &>/dev/null; then
  info "Claude Code already installed ($(claude --version 2>/dev/null || echo 'unknown version'))"
else
  warn "Installing Claude Code …"
  curl -fsSL https://claude.ai/install.sh | bash
  info "Claude Code installed"
fi

# ─── done ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  Setup complete!"
echo "  • Run 'nvim' to finish LazyVim plugin install"
echo "  • Run 'claude' to start Claude Code"
echo "══════════════════════════════════════════════════"
echo ""
