#!/usr/bin/env python3
"""Apply native terminal/VS Code colors, preserving backups of existing settings."""
import argparse
import ast
import datetime
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess


def detect_platform():
    if platform.system() == 'Darwin':
        return 'macos'
    return 'wsl' if 'microsoft' in platform.release().lower() else 'linux'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--home', type=Path, default=Path.home())
    parser.add_argument('--platform', choices=['auto', 'linux', 'macos', 'wsl'], default='auto')
    args = parser.parse_args()
    target = detect_platform() if args.platform == 'auto' else args.platform
    home = args.home.expanduser().resolve()
    repo = Path(__file__).resolve().parents[2]
    palette = json.loads((repo / 'linux_env/config/space/palette.json').read_text())
    backup = home / '.local/state/space/backups' / datetime.datetime.now().strftime('%Y%m%dT%H%M%S.%f')

    def save(relative, data):
        path = backup / relative
        if not args.dry_run:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            print(f'Backup: {path}')

    # The configuration installer installs Kitty and iTerm profiles; this step
    # integrates native settings databases and existing VS Code installations.
    if target == 'wsl':
        command = ['python3', str(repo / 'windows_env/tools/apply-native-look.py')]
        if args.dry_run:
            command.append('--dry-run')
        if home == Path.home().resolve():
            subprocess.run(command, check=True)
        else:
            print('Skip live Windows settings for an alternate home.')
        return
    code_path = home / ('Library/Application Support/Code/User/settings.json' if target == 'macos' else '.config/Code/User/settings.json')
    if code_path.exists():
        original = code_path.read_bytes()
        try:
            settings = json.loads(original.decode('utf-8-sig'))
        except ValueError:
            raise SystemExit(f'{code_path}: JSONC is not edited automatically; merge the palette manually.')
        before = json.dumps(settings, sort_keys=True)
        colors = settings.setdefault('workbench.colorCustomizations', {})
        for key in ['editor.background', 'terminal.background']:
            colors[key] = palette['background']
        for key in ['editor.foreground', 'terminal.foreground']:
            colors[key] = palette['foreground']
        colors.update({'editor.selectionBackground': '#b9d8ff66', 'terminal.selectionBackground': '#b9d8ff66',
                       'statusBar.background': '#293b53', 'statusBar.foreground': '#f3f6fc'})
        for name in ['black', 'red', 'green', 'yellow', 'blue', 'purple', 'cyan', 'white']:
            label = 'Magenta' if name == 'purple' else name.title()
            colors['terminal.ansi' + label] = palette[name]
            colors['terminal.ansiBright' + label] = palette['bright' + name.title()]
        os_key = 'osx' if target == 'macos' else 'linux'
        settings['terminal.integrated.defaultProfile.' + os_key] = 'Space Zsh'
        settings.setdefault('terminal.integrated.profiles.' + os_key, {})['Space Zsh'] = {'path': '/bin/zsh', 'args': ['-l']}
        if json.dumps(settings, sort_keys=True) != before:
            print(f'Update {code_path}')
            if not args.dry_run:
                save(str(code_path.relative_to(home)), original)
                code_path.write_text(json.dumps(settings, indent=4, ensure_ascii=False) + '\n')
    else:
        print(f'Skip missing VS Code settings: {code_path}')

    if home != Path.home().resolve() or target != detect_platform():
        print('Skip native GUI settings for an alternate home/platform.')
        return
    if target == 'macos':
        print('Import Space Navy into Terminal.app and select it for new windows.')
        print('iTerm2: select Space Navy in Profiles, then Other Actions > Set as Default.')
        if args.dry_run:
            return
        result = subprocess.run(['defaults', 'export', 'com.apple.Terminal', '-'], capture_output=True)
        if result.returncode == 0:
            save('macos/com.apple.Terminal.plist', result.stdout)
        profile = str(home / '.config/space/Space Navy.terminal')
        # Imported profiles are visible to the scripting interface. Never close
        # existing sessions or replace a live preferences file behind Terminal.
        script = '''on run argv
    tell application "Terminal"
        if not (exists settings set "Space Navy") then
            open (POSIX file (item 1 of argv))
        end if
        set font name of settings set "Space Navy" to "MesloLGS-NF-Regular"
        set font size of settings set "Space Navy" to 13
        set default settings to settings set "Space Navy"
        set startup settings to settings set "Space Navy"
    end tell
end run
'''
        subprocess.run(['osascript', '-', profile], input=script, text=True, check=True)
        return
    if not os.environ.get('DBUS_SESSION_BUS_ADDRESS'):
        print('No desktop session bus: GNOME settings skipped. xterm/Kitty profiles are installed.')
        return
    if not shutil.which('gsettings') or not shutil.which('dconf'):
        print('GNOME settings skipped: install gsettings and dconf to configure GNOME Terminal.')
        return
    schemas = subprocess.check_output(['gsettings', 'list-schemas'], text=True).splitlines()
    schema = 'org.gnome.Terminal.ProfilesList'
    if schema not in schemas:
        print('GNOME Terminal schema is not installed; xterm/Kitty profiles remain available.')
        return
    profile_id = '2280d9dc-b622-5b67-b16d-7631849ba212'
    print('Configure Space Navy GNOME Terminal profile and make it the default.')
    if args.dry_run:
        return
    save('linux/gnome-terminal.dconf', subprocess.check_output(['dconf', 'dump', '/org/gnome/terminal/legacy/']))
    current = ast.literal_eval(subprocess.check_output(['gsettings', 'get', schema, 'list'], text=True).removeprefix('@as '))
    if profile_id not in current:
        current.append(profile_id)
    subprocess.run(['gsettings', 'set', schema, 'list', repr(current)], check=True)
    profile_schema = f'org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:{profile_id}/'
    values = {'visible-name': 'Space Navy', 'use-theme-colors': False, 'use-system-font': False,
              'font': 'MesloLGS NF 11', 'background-color': palette['background'], 'foreground-color': palette['foreground'],
              'cursor-colors-set': True, 'cursor-background-color': palette['cursorColor'], 'cursor-foreground-color': palette['background'],
              'highlight-colors-set': True, 'highlight-background-color': palette['selectionBackground'], 'highlight-foreground-color': '#203149',
              'scrollback-lines': 50000, 'scrollback-unlimited': False, 'use-custom-command': True, 'custom-command': '/bin/zsh -l',
              'palette': [palette[n] for n in ['black','red','green','yellow','blue','purple','cyan','white']] +
                         [palette['bright' + n.title()] for n in ['black','red','green','yellow','blue','purple','cyan','white']]}
    for key, value in values.items():
        variant = str(value).lower() if isinstance(value, bool) else repr(value)
        subprocess.run(['gsettings', 'set', profile_schema, key, variant], check=True)
    subprocess.run(['gsettings', 'set', schema, 'default', profile_id], check=True)


if __name__ == '__main__':
    main()
