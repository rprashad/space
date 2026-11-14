# Shared terminal environment and native Linux setup

From the repository root:

```sh
./setup --dry-run
./setup
```

Python 3.9+ and Git are prerequisites on Linux. Package installation uses sudo when needed. The package branches cover apt-based Debian/Ubuntu, Fedora's dnf, and Arch's pacman. They install the terminal baseline: Zsh, Git, tmux, Neovim, ripgrep, fzf, jq, GitHub CLI, clipboard tools, fonts, and xterm. Arch uses a full `pacman -Syu` upgrade to avoid a partial upgrade. Review `--dry-run` before applying system package changes.

Neovim **0.10+** and tmux **3.2+** are required. An older distribution's default Neovim may not meet the requirement; bootstrap stops before installing the config if Neovim is too old. Install a current official/distribution build, then rerun `./setup --configs-only`. Language runtimes, language servers, cloud CLIs, containers, SSH credentials, and lab host mappings are outside this core terminal bootstrap. Existing tools remain available; `:LspStatus` lists the optional Neovim servers that are missing.

`--configs-only` skips packages, prompt repository clones and fonts. `--no-gui` skips native settings databases. Neither switches your account shell or deletes unrelated packages. Missing Oh My Zsh and Powerlevel10k are cloned only during dependency setup; existing checkouts are retained.

## Shell appearance

The shared Powerlevel10k ribbon shows the current directory and Git status on the left, and the machine's local IPv4 address, load, RAM, and time on the right. The IP segment uses the first active Ethernet/Wi-Fi interface (`en*`, `eth*`, `wl*`, or `ww*`), including WSL's Linux interface, and disappears when none has an address. It updates dynamically without an external IP service. In WSL this is the Linux instance's address, which can differ from the Windows host's LAN address.

The prompt lives in `config/zsh/p10k.zsh`; the installer links it to `~/.config/zsh/p10k.zsh`. After changing it, open a new shell or run `exec zsh -l`. The shared palette, terminal profiles, tmux styles, and Neovim colorscheme are included in this repository so `./setup` can restore the shell appearance on another machine.

## Linux terminal defaults

- `space-terminal` opens GNOME Terminal if installed, otherwise Kitty, otherwise xterm, running `/bin/zsh -l`. A Space Terminal desktop entry is installed, and `$TERMINAL` points to the launcher.
- GNOME Terminal gets a dedicated **Space Navy** profile selected as the default. Other profiles remain. Applying it requires GNOME Terminal's schema, gsettings/dconf, and a desktop session bus. Headless installs skip this step with an explanation.
- xterm uses `~/.Xresources`; the installer merges it when DISPLAY is available, and the launcher reloads it before opening xterm. Open a new window to see changes.
- Kitty gets `space-navy.conf`, included once at the end of `kitty.conf`. Existing Kitty settings remain, while the included palette/font/shell defaults take precedence.
- Existing VS Code user settings are merged with the palette and a Zsh login terminal profile. Unrelated keys remain. JSONC files are refused instead of stripping comments; merge those manually.

Wayland clipboard tools are preferred in native Linux graphical sessions; X11 uses xclip. Neovim and tmux use the same `clipboard-copy`/`clipboard-paste` commands. On headless SSH sessions there may be no local graphical clipboard. Clipboard forwarding from a remote host requires a separate explicit integration.

Ctrl+b then `[` enters tmux copy mode; `v` selects and `y` copies to the system clipboard. Ctrl+b then `]` fetches and pastes the current system clipboard, preserving trailing newlines and application-controlled bracketed paste. Holding Shift lets the terminal handle mouse selection. Native terminal copy/paste shortcuts remain unchanged.

## Sources, backups, and checks

Shared files live under `linux_env/config` and the dotfiles in this directory. Platform overrides are selected from `linux_env/config/space`, `mac_env/config`, or `windows_env/config`. Windows-only executable links are removed when switching a managed home to a native platform; unrelated executables are retained. Keep the checkout in place after installation because the files are symlinked.

Replaced files are backed up under `~/.local/state/space/backups/<timestamp>/`. Native GUI integration saves its settings backups there too. To restore a reviewed file backup, use `cp -a --remove-destination <backup-directory>/. "$HOME/"` so restored files replace symlinks rather than modifying the repository. New files have no prior version and must be removed separately when rolling back. GNOME settings snapshots are restored with `dconf load /org/gnome/terminal/legacy/ < <backup>/linux/gnome-terminal.dconf`.

The shared terminal palette is `config/space/palette.json`. Generated xterm, WSL xterm, Kitty, Terminal.app, and iTerm2 assets must be regenerated after editing it:

```sh
python3 linux_env/tools/render-terminal-profiles.py
python3 linux_env/tools/render-terminal-profiles.py --check
python3 linux_env/tools/apply-terminal-look.py
```

The Neovim colorscheme and tmux styles are separately maintained alongside the palette; update them together if changing the visual design. `apply-terminal-look.py` handles Linux/macOS and dispatches to Windows integration in WSL. `install-terminal.py --home <directory> --platform linux|macos|wsl` stages configuration without changing your real desktop session.

```sh
space-doctor
python3 linux_env/tests/test-install.py
python3 linux_env/tests/test-paste.py
```

Tests cover platform staging/detection, idempotence, backups, path names containing spaces, preserving unrelated VS Code settings, generated profile data, mock clipboard backends, and real Zsh/tmux paste. They do not change the real clipboard. A GitHub Actions workflow runs the suites on Linux and macOS when these changes are pushed; native GUI appearance still needs a real desktop check. The current implementation was exercised locally in WSL, not on a physical Mac.

References: [GNOME Terminal settings schema](https://github.com/GNOME/gnome-terminal/blob/master/src/org.gnome.Terminal.gschema.xml), [Kitty configuration](https://sw.kovidgoyal.net/kitty/conf/).
