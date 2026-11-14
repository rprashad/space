# Windows and WSL terminal environment

The defaults retain the existing navy background (`#34465f`), light text, pastel selections, and Powerline prompt. Zsh, tmux, Neovim, xterm, Windows Terminal, and VS Code use the same palette. Windows-specific scripts and configuration live here; portable settings live in `../linux_env`.

## Apply and maintain

From the repository root, in WSL:

```sh
python3 linux_env/tools/install-terminal.py --dry-run
python3 linux_env/tools/install-terminal.py
python3 windows_env/tools/apply-native-look.py --dry-run
python3 windows_env/tools/apply-native-look.py
```

The Linux installer uses symlinks, backs up replaced files under `~/.local/state/space/backups/<timestamp>/`, and reloads the running tmux server without terminating sessions. Rerunning it is safe. Edit the repository sources afterward, then reload tmux or open a new shell as appropriate. Avoid moving the checkout without reinstalling the links.

The Windows settings merger discovers the Windows user's AppData directories, merges existing JSON, preserves other settings, and saves timestamped `.space-backup-*` files beside changed settings. It sets Windows Terminal's default profile to this WSL distribution and makes VS Code integrated terminals start WSL. JSONC settings with comments/trailing commas are refused, so they can be merged manually without losing comments. Existing per-profile color overrides can take precedence over Windows Terminal defaults.

Open a **new xterm** to pick up X resources and new shell bindings. Existing tmux panes need `exec zsh -l` for shell changes. The Windows apps may need a new tab/window. No SSH key material, tokens, clipboard contents, or machine hosts files are stored in this repo.

To restore Linux configuration, review the chosen backup directory, then copy it over the managed files using `cp -a --remove-destination <backup-directory>/. "$HOME/"`. This removes destination symlinks before restoring files. Restore Windows settings from their adjacent backups with the apps closed. Files newly created by installation have no previous version; remove those links separately if rolling back fully.

## Dependencies and tools

`finish-wsl-setup` installs Debian terminal dependencies, Oh My Zsh/Powerlevel10k if missing, and language servers, then applies these defaults. Run it interactively: apt and changing the login shell can require your sudo password. Node/npm must already be available. It uses distribution Neovim and does not upgrade all development runtimes.

The MesloLGS NF font is optional but recommended for the Powerline prompt. Install it for Linux/fontconfig for xterm; Windows Terminal and VS Code use their installed native fonts. xterm uses the existing toolbar build at `~/.local/opt/xterm-toolbar/bin/xterm` when present and falls back to `/usr/bin/xterm`.

`code`, `code .`, and `code <path>` use Windows VS Code connected to the current WSL distro. With no arguments it opens the current Linux directory. Install Windows VS Code plus its WSL extension. If multiple Windows installations exist, set `CODE_WSL_LAUNCHER` to the desired `bin/code` path.

`python3 windows_env/tools/install-github-cli.py` installs or updates GitHub CLI from its official release and checks the published SHA-256 before replacing `~/.local/bin/gh`. It requires no sudo. Authenticate separately with `gh auth login`.

Neovim uses the shared palette, system clipboard commands, completion, and available language servers. `:LspStatus` lists missing servers. The setup script installs Python, JS/TS, JSON/CSS/HTML, YAML, Ruby, and Rust servers; Terraform and Terragrunt servers must be installed separately as `terraform-ls` and `terragrunt-ls`.

## Copy, paste, and responsiveness

- xterm: Ctrl+Shift+C / Ctrl+Shift+V; Shift+Insert also pastes.
- tmux: Ctrl+b then `[` enters copy mode; `v` selects, `y` copies to Windows. Mouse selection in copy mode also copies.
- Ctrl+b then `]` fetches the current Windows clipboard and pastes into that pane.
- Hold Shift while dragging to select with xterm instead of tmux.
- Shell: `command | clipboard-copy`, `clipboard-paste | command`; WSL aliases `ccopy` and `cpaste` remain available.

The WSLg X clipboard is the primary path; Windows executables are fallbacks. tmux copy-pipe is the single clipboard writer here, avoiding a competing OSC 52 update. The tmux paste helper uses a unique buffer per invocation and `paste-buffer -p`, which emits bracketed paste only when the destination application requests it. Zsh uses its built-in literal paste widget instead of Oh My Zsh's per-character paste processing. Readline bracketed paste remains enabled.

`^[[200~` / `^[[201~` or `0~` / `1~` at paste boundaries can indicate leaked bracketed-paste framing. These are terminal control sequences, not smart quotes. Curly quotes present in source text remain untouched. Restart the affected shell first; use `reset` if an application exited leaving terminal modes behind. Do not globally disable bracketed paste: it lets supporting shells keep multiline input editable before execution. See [xterm's paste documentation](https://invisible-island.net/xterm/xterm-paste64.html) and [tmux's clipboard guide](https://github.com/tmux/tmux/wiki/Clipboard).

Every xterm launch previously waited for PowerShell/clipboard synchronization; that check is now explicit and never blocks opening a terminal. CPU metrics no longer spawn Python on every prompt redraw. tmux status refresh is 15 seconds, xterm batches scrolling, and cursor blinking is disabled. Actual interactive smoothness still needs observation in a newly opened terminal.

```sh
terminal-doctor                       # read-only tool/transport checks
clipboard-check --test                # changes then restores TEXT clipboard; explicit only
python3 windows_env/tests/test-terminal.py
```

The automated test stages an installation twice, then uses a real Zsh PTY and a private tmux server to check Unicode, curly quotes, multiline text, and shell metacharacters without executing the paste. It substitutes a fake clipboard and never changes your real one. It does not simulate the Windows browser or every GUI shortcut. `clipboard-check --test` is for text clipboards only; avoid it when preserving images or rich formats.

## Browser / lab hostname troubleshooting

Windows browsers use the Windows hosts file, while WSL uses `/etc/hosts`. Keep the intended entries in both. DNS maps names to IPs, not ports: use a full URL such as `https://host.example:8006/` for Proxmox.

```sh
terminal-doctor host.example 8006
getent ahostsv4 host.example
powershell.exe -NoProfile -Command '[System.Net.Dns]::GetHostAddresses("host.example")'
powershell.exe -NoProfile -Command 'Test-NetConnection host.example -Port 8006'
```

If both resolvers return the intended IP but TCP fails, check the server's current IP, power, LAN/VLAN route, firewall, and service. An HTTP response proves connectivity even if a HEAD request receives HTTP 501. A browser certificate warning is a separate TLS issue. Do not change a hosts mapping to another machine merely because that machine responds.
