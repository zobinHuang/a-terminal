# VibeBox

One-line setup for a vibe-coding terminal environment.

```bash
curl -fsSL -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/zobinHuang/vibebox/contents/setup.sh | bash
```

Re-run it to upgrade. Open sessions reload in place — no restart.

## Sessions

```bash
vbox new <name>       vbox ls
vbox attach <name>    vbox kill <name>      vbox exit
```

Named `<username>-<name>`.

## Keys

**Tabs** — `Ctrl+t` then:

| Key | |
|---|---|
| `n` `r` `x` | new · rename · close |
| `←` `→` or `h` `l` | switch |
| `1`–`9` | jump to tab |
| `c` | clear a stuck agent state |

**Panes** — `Ctrl+p` then:

| Key | |
|---|---|
| `d` `n` | split down · right |
| arrows or `h` `j` `k` `l` | navigate |
| `x` `z` | close · zoom |

**Resize** — `Ctrl+n` then arrows or `h` `j` `k` `l`, repeatable.

**Anytime:**

| Key | |
|---|---|
| `Alt+←→` | panes, then along the status bar |
| `Alt+↑↓` | panes |
| `F12` | passthrough to a nested tmux (`[PASSTHRU]`) |

## Agent bar

Tabs split into two rows by what the agent in them is doing:

```
 READY     1:shell    2:notes  ○ 3:agent  ! 5:api
 BUSY    ▸ ● 4:kernel  ● 6:paper
 VibeBox [host]  ◆ session              running 5m 30s │ 2026-06-13 14:14
```

`●` working · `○` idle · `!` blocked on a prompt · dim = no agent · `▸` current

An empty row is hidden, so with no agent anywhere the bar is a single line.
`Alt+←→` walks both rows as one sequence, in the order you read them.

State comes from Claude Code and codex hooks, merged into
`~/.claude/settings.json` and `~/.codex/hooks.json`. Your own hooks are left
alone. **Codex needs `/hooks` → *Trust all* once**, or its tabs never go BUSY.

A tab stuck in BUSY (agent killed outright) clears with `Ctrl+t` `c`.
An agent inside a *nested* tmux — SSH'd into a remote `vbox` — is not tracked.

## Files

```
~/.local/bin/     vbox · vbox-agent · vbox-uptime · osc52-copy
~/.tmux.conf      ~/.vimrc
~/.claude/settings.json   ~/.codex/hooks.json
```
