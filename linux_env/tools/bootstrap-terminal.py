#!/usr/bin/env python3
"""Install core terminal tools and apply shared/native defaults."""
import argparse
import os
from pathlib import Path
import platform
import shlex
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--dry-run', action='store_true')
parser.add_argument('--configs-only', action='store_true', help='skip packages, fonts and prompt dependencies')
parser.add_argument('--no-gui', action='store_true', help='skip native settings database changes')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
is_mac = platform.system() == 'Darwin'
is_wsl = platform.system() == 'Linux' and 'microsoft' in platform.release().lower()
if platform.system() not in ['Linux', 'Darwin']:
    parser.error('Run in Linux, WSL, or macOS.')


def run(command):
    print('+ ' + shlex.join(map(str, command)), flush=True)
    if not args.dry_run:
        subprocess.run(list(map(str, command)), check=True)


if not args.configs_only:
    if is_mac:
        if not shutil.which('brew'):
            raise SystemExit('Install Homebrew from https://brew.sh/ first.')
        run(['brew', 'bundle', '--file', repo / 'mac_env/Brewfile'])
    else:
        sudo = [] if os.geteuid() == 0 else ['sudo']
        base = ['zsh', 'git', 'curl', 'ca-certificates', 'tmux', 'neovim', 'ripgrep', 'fzf', 'jq', 'xclip', 'wl-clipboard', 'fontconfig', 'xterm']
        if shutil.which('apt-get'):
            run(sudo + ['apt-get', 'update'])
            run(sudo + ['apt-get', 'install', '-y'] + base + ['python3', 'ncurses-term', 'gh', 'dconf-cli', 'libglib2.0-bin', 'x11-xserver-utils'])
        elif shutil.which('dnf'):
            run(sudo + ['dnf', 'install', '-y'] + base + ['python3', 'ncurses-term', 'gh', 'dconf', 'glib2', 'xrdb'])
        elif shutil.which('pacman'):
            run(sudo + ['pacman', '-Syu', '--needed', '--noconfirm'] + base + ['python', 'ncurses', 'github-cli', 'dconf', 'glib2', 'xorg-xrdb'])
        else:
            raise SystemExit('Supported package managers: apt-get, dnf, pacman, Homebrew. Install dependencies manually, then use --configs-only.')
    # Install only missing prompt repositories; do not pull on every terminal start.
    dependencies = [
        ('https://github.com/ohmyzsh/ohmyzsh.git', Path.home() / '.oh-my-zsh'),
        ('https://github.com/romkatv/powerlevel10k.git', Path.home() / '.oh-my-zsh/custom/themes/powerlevel10k'),
    ]
    for url, destination in dependencies:
        if not destination.exists():
            run(['git', 'clone', '--depth=1', url, destination])
    run([sys.executable, repo / 'linux_env/tools/install-terminal-fonts.py'])

# Make freshly installed Homebrew terminfo visible before platform.sh is linked.
if is_mac and not args.dry_run:
    prefix = subprocess.check_output(['brew', '--prefix', 'ncurses'], text=True).strip()
    os.environ['TERMINFO_DIRS'] = prefix + '/share/terminfo:' + os.environ.get('TERMINFO_DIRS', '')

# Check the actual installed Neovim before applying configuration using 0.10 APIs.
if not args.dry_run:
    for tool in ['zsh', 'tmux', 'nvim']:
        if not shutil.which(tool):
            raise SystemExit(f'Missing {tool}; install dependencies before using --configs-only.')
    check = subprocess.run(['nvim', '--clean', '--headless', '+lua if vim.fn.has("nvim-0.10") == 0 then vim.cmd("cquit 1") end', '+qa'])
    if check.returncode:
        raise SystemExit('Neovim 0.10+ is required. Upgrade Neovim using your distro/official packages, then rerun ./setup --configs-only.')
run([sys.executable, repo / 'linux_env/tools/install-terminal.py'])
if not args.no_gui:
    run([sys.executable, repo / 'linux_env/tools/apply-terminal-look.py'])
if not args.dry_run:
    print('Open a new terminal. Zsh is configured for the native profiles; use chsh -s /bin/zsh if you also want it as your account login shell.')
