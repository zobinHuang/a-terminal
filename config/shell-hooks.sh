# [vibebox] vibe-music shell hooks — sourced from ~/.zshrc / ~/.bashrc.
#
# Reports each shell's running/idle state to vbox-music so the per-pane
# vibe transitions while you type and run commands. Silent and side-effect
# free outside a vibe-mode tmux session: registration is gated on the
# session having an active @vibe-active-slot at shell-startup time.

_vbox_should_hook() {
  [ -n "${TMUX:-}" ] || return 1
  [ -n "${TMUX_PANE:-}" ] || return 1
  command -v vbox-music >/dev/null 2>&1 || return 1
  command -v tmux       >/dev/null 2>&1 || return 1
  local sess active
  sess="$(tmux display-message -p '#{session_id}' 2>/dev/null)"
  [ -n "$sess" ] || return 1
  active="$(tmux show-options -v -t "$sess" @vibe-active-slot 2>/dev/null)"
  [ -n "$active" ]
}

if _vbox_should_hook; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    _vbox_preexec() { vbox-music set-state "$TMUX_PANE" running 2>/dev/null; }
    _vbox_precmd()  { vbox-music set-state "$TMUX_PANE" idle    2>/dev/null; }
    # zsh chains its hooks via these arrays; appending preserves any user hooks.
    typeset -ga preexec_functions precmd_functions
    preexec_functions+=(_vbox_preexec)
    precmd_functions+=(_vbox_precmd)
  elif [ -n "${BASH_VERSION:-}" ]; then
    _vbox_debug() {
      # skip tab-completion + the PROMPT_COMMAND chain itself
      [ -n "${COMP_LINE:-}" ] && return 0
      [ "$BASH_COMMAND" = "${PROMPT_COMMAND:-}" ] && return 0
      vbox-music set-state "${TMUX_PANE:-}" running 2>/dev/null
    }
    _vbox_precmd() { vbox-music set-state "${TMUX_PANE:-}" idle 2>/dev/null; }
    trap '_vbox_debug' DEBUG
    # prepend so other hooks still run; preserves any pre-existing PROMPT_COMMAND
    if [ -z "${PROMPT_COMMAND:-}" ]; then
      PROMPT_COMMAND="_vbox_precmd"
    else
      case ";$PROMPT_COMMAND;" in
        *";_vbox_precmd;"*) ;;  # already wired
        *) PROMPT_COMMAND="_vbox_precmd; $PROMPT_COMMAND" ;;
      esac
    fi
  fi
fi
unset -f _vbox_should_hook 2>/dev/null
