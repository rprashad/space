#!/usr/bin/env python3
"""Merge the shared navy palette into Windows Terminal and VS Code (with backups)."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--dry-run', action='store_true')
a = p.parse_args()
# Ask Windows for its current user's paths rather than assuming a username/drive.
ps = '/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
def windows_path(name):
    value = subprocess.check_output([ps, '-NoProfile', '-NonInteractive', '-Command', f'[Console]::Write($env:{name})'], text=True).strip()
    return Path(subprocess.check_output(['wslpath', '-u', value], text=True).strip())
local, roaming = windows_path('LOCALAPPDATA'), windows_path('APPDATA')
repo = Path(__file__).resolve().parents[2]
scheme = json.loads((repo / 'linux_env/config/space/palette.json').read_text())
stamp = datetime.datetime.now().strftime('%Y%m%dT%H%M%S.%f')

def update(path, change):
    if not path.exists():
        print(f'Skip missing {path}')
        return
    # Refuse JSONC rather than discarding comments or accidentally damaging settings.
    try:
        data = json.loads(path.read_text(encoding='utf-8-sig'))
    except ValueError:
        raise SystemExit(f'{path}: contains JSON comments/trailing commas; merge linux_env/config/space/palette.json manually.')
    before = json.dumps(data, sort_keys=True)
    change(data)
    if json.dumps(data, sort_keys=True) == before:
        print(f'Already configured: {path}')
        return
    print(f'Update {path}')
    if not a.dry_run:
        backup = path.with_name(path.name + '.space-backup-' + stamp)
        shutil.copy2(path, backup)
        path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + '\n', encoding='utf-8')
        print(f'Backup: {backup}')

def terminal(data):
    schemes = data.setdefault('schemes', [])
    schemes[:] = [s for s in schemes if s.get('name') != scheme['name']] + [scheme]
    defaults = data.setdefault('profiles', {}).setdefault('defaults', {})
    defaults.update(colorScheme=scheme['name'], cursorShape='bar', useAcrylic=False)
    for profile in data['profiles'].get('list', []):
        if profile.get('source') == 'Microsoft.WSL' and profile.get('name') == os.environ.get('WSL_DISTRO_NAME', 'Debian'):
            data['defaultProfile'] = profile['guid']
    data['copyFormatting'] = 'none'

def vscode(data):
    colors = data.setdefault('workbench.colorCustomizations', {})
    for key in ['editor.background', 'terminal.background']:
        colors[key] = scheme['background']
    for key in ['editor.foreground', 'terminal.foreground']:
        colors[key] = scheme['foreground']
    colors.update({'editor.selectionBackground': '#b9d8ff66', 'terminal.selectionBackground': '#b9d8ff66', 'statusBar.background': '#293b53', 'statusBar.foreground': '#f3f6fc'})
    for name in ['black','red','green','yellow','blue','purple','cyan','white']:
        label = 'Magenta' if name == 'purple' else name.title()
        colors['terminal.ansi' + label] = scheme[name]
        colors['terminal.ansiBright' + label] = scheme['bright' + name.title()]
    data['terminal.integrated.defaultProfile.windows'] = os.environ.get('WSL_DISTRO_NAME', 'Debian') + ' (WSL)'
    profiles = data.setdefault('terminal.integrated.profiles.windows', {})
    profiles[data['terminal.integrated.defaultProfile.windows']] = {'path': 'C:\\Windows\\System32\\wsl.exe', 'args': ['-d', os.environ.get('WSL_DISTRO_NAME', 'Debian')]}
    data['terminal.integrated.copyOnSelection'] = False

for candidate in [local / 'Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json', local / 'Microsoft/Windows Terminal/settings.json']:
    update(candidate, terminal)
update(roaming / 'Code/User/settings.json', vscode)
