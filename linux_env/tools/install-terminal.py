#!/usr/bin/env python3
"""Install explicit terminal defaults, with backups and no network mutations."""
import argparse
import datetime
import os
import platform
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--dry-run', action='store_true')
parser.add_argument('--home', type=Path, default=Path.home(), help='alternate home for staging')
parser.add_argument('--platform', choices=['auto', 'linux', 'wsl', 'macos'], default='auto')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
home = args.home.expanduser().resolve()
target_platform = args.platform
if target_platform == 'auto':
    if platform.system() == 'Darwin':
        target_platform = 'macos'
    elif platform.system() == 'Linux':
        target_platform = 'wsl' if 'microsoft' in platform.release().lower() else 'linux'
    else:
        parser.error('Supported systems: Linux, WSL, and macOS')
wsl = target_platform == 'wsl'
backup = home / '.local/state/space/backups' / datetime.datetime.now().strftime('%Y%m%dT%H%M%S.%f')


def save(target):
    if target.exists() or target.is_symlink():
        dest = backup / target.relative_to(home)
        dest.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink():
            dest.symlink_to(os.readlink(target))
        else:
            shutil.copy2(target, dest)


def install(source, relative):
    source, target = repo / source, home / relative
    if target.is_symlink() and target.resolve() == source.resolve():
        return
    print(f'{target} -> {source}')
    if args.dry_run:
        return
    save(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.unlink(missing_ok=True)
    target.symlink_to(source)


for name in ['.zshrc', '.zprofile', '.profile', '.tmux.conf', '.inputrc']:
    install('linux_env/' + name, name)
for source in (repo / 'linux_env/config').rglob('*'):
    if source.is_file() and source.name not in ['platform.sh', 'platform.zsh', 'tmux-platform.conf']:
        install(str(source.relative_to(repo)), '.config/' + str(source.relative_to(repo / 'linux_env/config')))
# Remove only obsolete links managed by this checkout when switching platforms.
if not wsl:
    for candidate in (repo / 'windows_env/tools').iterdir():
        target = home / '.local/bin' / candidate.name
        if target.is_symlink() and target.resolve() == candidate.resolve():
            print(f'Remove WSL-only link {target}')
            if not args.dry_run:
                save(target)
                target.unlink()
    target = home / '.local/bin/xterm'
    if target.is_symlink() and target.resolve() == repo / 'windows_env/tools/xterm-wsl':
        print(f'Remove WSL-only link {target}')
        if not args.dry_run:
            save(target)
            target.unlink()
    for name in ['clipboard-copy', 'clipboard-paste']:
        install('linux_env/tools/' + name, '.local/bin/' + name)
for name in ['tmux-paste-clipboard', 'space-doctor', 'space-terminal', 'apply-terminal-look.py']:
    install('linux_env/tools/' + name, '.local/bin/' + name)
platform_dir = {'wsl': 'windows_env', 'linux': 'linux_env', 'macos': 'mac_env'}[target_platform]
for name in ['platform.sh', 'platform.zsh', 'tmux-platform.conf']:
    install(platform_dir + '/config/' + name, '.config/space/' + name)
if target_platform == 'linux':
    install('linux_env/config/space/Xresources', '.Xresources')
elif target_platform == 'macos':
    install('mac_env/config/Space Navy.terminal', '.config/space/Space Navy.terminal')
    install('mac_env/config/iterm2-space.json', 'Library/Application Support/iTerm2/DynamicProfiles/space.json')
if wsl:
    for source in (repo / 'windows_env/tools').iterdir():
        if source.is_file():
            install(str(source.relative_to(repo)), '.local/bin/' + source.name)
    install('windows_env/config/Xresources', '.Xresources')
    install('windows_env/tools/win-copy', '.local/bin/clipboard-copy')
    install('windows_env/tools/win-paste', '.local/bin/clipboard-paste')
    install('windows_env/tools/xterm-wsl', '.local/bin/xterm')

# Bash retains its distribution defaults and loads the same environment.
line = '[ ! -r "$HOME/.config/zsh/environment.sh" ] || . "$HOME/.config/zsh/environment.sh"'
def append_line(relative, line):
    target = home / relative
    existing = target.read_text() if target.exists() else ''
    if line not in existing.splitlines():
        print(f'Append Space settings to {target}')
        if not args.dry_run:
            save(target)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(existing + '\n# Space terminal environment\n' + line + '\n')


append_line('.bashrc', line)
if target_platform == 'macos' or (home / '.bash_profile').exists():
    append_line('.bash_profile', line)
append_line('.config/kitty/kitty.conf', 'include space-navy.conf')
if target_platform == 'linux':
    desktop = home / '.local/share/applications/space-terminal.desktop'
    content = ('[Desktop Entry]\nType=Application\nName=Space Terminal\n'
               f'Exec="{home}/.local/bin/space-terminal"\nIcon=utilities-terminal\n'
               'Terminal=false\nCategories=System;TerminalEmulator;\n')
    if not desktop.exists() or desktop.read_text() != content:
        print(f'Write {desktop}')
        if not args.dry_run:
            save(desktop)
            desktop.parent.mkdir(parents=True, exist_ok=True)
            desktop.write_text(content)
if target_platform == 'linux':
    terminal_list = home / '.config/xdg-terminals.list'
    if not terminal_list.exists():
        print(f'Write {terminal_list}')
        if not args.dry_run:
            terminal_list.write_text('space-terminal.desktop\n')
if wsl:
    desktop = home / '.local/share/applications/xterm-wsl.desktop'
    content = ('[Desktop Entry]\nType=Application\nName=WSL Xterm\n'
               'Comment=Zsh and Windows clipboard\n'
               f'Exec="{home}/.local/bin/xterm-wsl"\nIcon=xterm\nTerminal=false\nCategories=System;TerminalEmulator;\n')
    if not desktop.exists() or desktop.read_text() != content:
        print(f'Write {desktop}')
        if not args.dry_run:
            save(desktop)
            desktop.parent.mkdir(parents=True, exist_ok=True)
            desktop.write_text(content)
    terminal_list = home / '.config/xdg-terminals.list'
    if not terminal_list.exists():
        if not args.dry_run:
            terminal_list.write_text('xterm-wsl.desktop\n')
if not args.dry_run:
    print(f'Backups (for changed existing files): {backup}')
    if home == Path.home().resolve():
        if shutil.which('tmux') and subprocess.run(['tmux', 'list-sessions'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            subprocess.run(['tmux', 'source-file', str(home / '.tmux.conf')], check=True)
        if target_platform in ['wsl', 'linux'] and os.environ.get('DISPLAY') and shutil.which('xrdb'):
            subprocess.run(['xrdb', '-merge', str(home / '.Xresources')], check=True)
    print('Open a new terminal for shell/input settings. Existing tmux sessions remain running.')
