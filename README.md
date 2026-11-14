# space

Personal tools and a shared terminal environment for Linux, macOS, and Windows through WSL.

```sh
./setup --dry-run
./setup
```

The setup installs core terminal tools, missing Oh My Zsh/Powerlevel10k checkouts, and MesloLGS NF fonts, then links the shared configuration and applies supported native profiles. Existing files are backed up. On macOS, install [Homebrew](https://brew.sh/) first; `setup` can then install Python itself. Linux needs Python 3 to start.

| Platform | Setup path | Native terminal integration |
| --- | --- | --- |
| Linux | apt, dnf, or pacman | GNOME Terminal, xterm, Kitty |
| macOS | Homebrew, Apple Silicon or Intel | Terminal.app, iTerm2, Kitty |
| Windows | Run `./setup` inside WSL | Windows Terminal, WSL xterm, VS Code |

The same Zsh, tmux, Readline, Neovim, clipboard commands, and navy palette are shared. Native clipboard backends are `pbcopy`/`pbpaste`, Wayland, X11, or the WSLg bridge. Other terminal emulators keep their existing application profiles until explicit support is added; this does not change an entire OS desktop theme.

- [`linux_env/`](linux_env/README.md): shared configuration, native Linux setup, tests, and profile generation.
- [`mac_env/`](mac_env/README.md): macOS dependencies and native profiles.
- [`windows_env/`](windows_env/README.md): Windows and WSL overrides.

Use `./setup --configs-only` to skip dependency installation, or `--no-gui` to skip native settings database changes. Open a new terminal afterward. The setup configures Zsh in the supported profiles/launcher; changing your account login shell is a separate `chsh -s /bin/zsh` choice.

Configuration-only install and staging:

```sh
python3 linux_env/tools/install-terminal.py --dry-run
python3 linux_env/tools/install-terminal.py
python3 linux_env/tools/install-terminal.py --platform macos --home /tmp/space-mac-preview
```

The installer links only its explicit file list. It never pulls this repo on shell startup or loads the historical `linux_env/profile.d` snippets. `linux_env/tools/linuxenv_sync.sh` forwards to the explicit installer. Existing Perl, Python, infrastructure, and lab projects remain in their respective directories.
