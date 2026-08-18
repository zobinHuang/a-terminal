# VibeBox

Keep your coding agents running, and see which one needs you.

![VibeBox](docs/screenshot.png)

## Install

```bash
curl -fsSL -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/zobinHuang/vibebox/contents/setup.sh | bash
```

## Usage

```bash
vbox new <name>       vbox ls
vbox attach <name>    vbox kill <name>       vbox exit
```

`●` working · `○` idle · `!` blocked · dim = no agent · `▸` current

| Key | |
|---|---|
| `Ctrl+t` `n` `r` `x` | tab: new · rename · close |
| `Ctrl+t` `←` `→` or `1`–`9` | switch tab |
| `Ctrl+t` `c` | clear a tab stuck as busy |
| `Ctrl+p` `d` `n` | split down · right |
| `Ctrl+p` arrows · `x` · `z` | panes: move · close · zoom |
| `Ctrl+n` arrows | resize pane |
| `Alt+←` `→` | panes, then along the bar |
| `Alt+↑` `↓` | panes |
| `F12` | passthrough to a nested tmux |
