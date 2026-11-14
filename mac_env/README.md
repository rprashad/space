# macOS terminal setup

Install [Homebrew](https://brew.sh/) and clone this repo, then run:

```sh
cd ~/git/space
./setup --dry-run
./setup
```

The entrypoint discovers Homebrew on Apple Silicon (`/opt/homebrew`) or Intel (`/usr/local`), installs Homebrew Python if needed, then uses `mac_env/Brewfile` for the core tools and iTerm2. Homebrew or macOS may request its normal installation/automation permissions. An existing Homebrew installation is required; this setup does not run Homebrew's remote installer automatically.

The bootstrap installs the shared Zsh, tmux, Readline, Neovim and clipboard configuration. `pbcopy` and `pbpaste` are used directly, preserving Unicode and trailing newlines. GNU `ls` options are avoided. MesloLGS NF fonts are installed in `~/Library/Fonts`; they come from Powerlevel10k's upstream font repository. Dependency configuration, API keys and authentication are separate from this terminal baseline.

## Native application profiles

**Terminal.app:** the generated `Space Navy.terminal` profile is installed at `~/.config/space/Space Navy.terminal`. Native integration imports it if missing, selects it for default/startup windows, and sets the Meslo font. It may open a Terminal window and macOS may ask to allow automation. Existing sessions are not closed. On repeat runs an existing profile is reused to avoid duplicate imports; if you change its ANSI palette later, remove/reimport the profile in Terminal Settings before applying it again.

If skipping GUI integration, import it manually in Terminal > Settings > Profiles > Import, select Space Navy, set font to MesloLGS NF, and choose Default. Apple documents [profile import/export](https://support.apple.com/guide/terminal/import-and-export-profiles-trml4299c696/mac).

**iTerm2:** a generated [Dynamic Profile](https://iterm2.com/documentation-dynamic-profiles.html) is linked at `~/Library/Application Support/iTerm2/DynamicProfiles/space.json`. Open Profiles and select **Space Navy**. To use it for every new window, select it in Settings > Profiles and choose **Other Actions > Set as Default** once. Existing defaults are not replaced behind a running iTerm2 instance. The profile runs `/bin/zsh -l` and inherits unspecified native preferences.

**Kitty:** the shared palette/font/shell include is installed when configuring the home. Kitty itself is optional and is not installed by the Brewfile.

**VS Code:** if its native user settings exist, integration merges the colors and a Zsh login terminal. It does not install or require Windows VS Code. On macOS, use VS Code's **Shell Command: Install 'code' command in PATH** action if you need its CLI.

Terminal.app's profile declares `nsterm-256color`, and Neovim uses explicit indexed colors outside tmux. Inside tmux, RGB can be converted to the outer terminal's capabilities. iTerm2 and Kitty retain true-color rendering. Homebrew's ncurses terminfo directory is added with system fallback paths preserved. Remote SSH hosts also need the matching terminfo entry (for example, Debian's `ncurses-term`); iTerm2 keeps the commonly available `xterm-256color` declaration.

Open a new window after setup. `space-terminal` opens Terminal.app; `space-doctor` checks the shared tools. `--no-gui` defers native database changes; `--configs-only` requires an existing Python 3 and installed baseline tools. To apply the native look later:

```sh
python3 linux_env/tools/apply-terminal-look.py
```

Before changes, Terminal preferences are exported to `~/.local/state/space/backups/<timestamp>/macos/com.apple.Terminal.plist` when they exist. To restore, close Terminal first and import the reviewed snapshot using `defaults import com.apple.Terminal <backup-file>` from another terminal app. Existing VS Code settings and shell files also get backups; see the [shared setup guide](../linux_env/README.md).

The generated profiles and simulated macOS installation/clipboard behavior are tested from WSL. The native Terminal.app AppleScript and visual appearance require validation on a real Mac; no such run has been performed in this session. GitHub Actions includes a macOS runner for non-GUI checks after the changes are pushed.

References: [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile), [iTerm2 Dynamic Profiles](https://iterm2.com/documentation-dynamic-profiles.html).
