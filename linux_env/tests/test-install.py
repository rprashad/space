#!/usr/bin/env python3
"""Cross-platform installation, backup, palette, and clipboard backend checks."""
import contextlib
import io
import json
import os
from pathlib import Path
import plistlib
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[2]
INSTALLER = REPO / 'linux_env/tools/install-terminal.py'


class TerminalSetup(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='space-install-')
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / 'home with spaces'
        self.home.mkdir()

    def install(self, target, *extra):
        return subprocess.check_output([sys.executable, str(INSTALLER), '--home', str(self.home), '--platform', target, *extra], text=True)

    def test_platforms_and_idempotence(self):
        for target in ['linux', 'macos', 'wsl']:
            with self.subTest(target=target):
                self.install(target)
                self.assertEqual(self.install(target, '--dry-run'), '')
                source = (self.home / '.config/space/platform.sh').resolve()
                directory = {'linux': 'linux_env', 'macos': 'mac_env', 'wsl': 'windows_env'}[target]
                self.assertEqual(source, REPO / directory / 'config/platform.sh')
                self.assertTrue((self.home / '.local/bin/tmux-paste-clipboard').exists())
        self.assertTrue((self.home / 'Library/Application Support/iTerm2/DynamicProfiles/space.json').exists())

    def test_darwin_auto_detection_without_proc(self):
        with patch.object(sys, 'argv', [str(INSTALLER), '--home', str(self.home)]), patch('platform.system', return_value='Darwin'), contextlib.redirect_stdout(io.StringIO()):
            runpy.run_path(str(INSTALLER), run_name='__main__')
        self.assertEqual((self.home / '.config/space/platform.sh').resolve(), REPO / 'mac_env/config/platform.sh')

    def test_backup_and_dry_run(self):
        original = '# original zsh settings\n'
        (self.home / '.zshrc').write_text(original)
        self.install('macos', '--dry-run')
        self.assertEqual((self.home / '.zshrc').read_text(), original)
        self.assertFalse((self.home / '.config').exists())
        self.install('macos')
        backups = list((self.home / '.local/state/space/backups').glob('*/.zshrc'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), original)

    def test_switch_from_wsl_removes_managed_windows_tools(self):
        self.install('wsl')
        self.install('macos')
        self.assertFalse((self.home / '.local/bin/code').exists())
        self.assertFalse((self.home / '.local/bin/xterm').exists())
        self.assertEqual((self.home / '.local/bin/clipboard-copy').resolve(), REPO / 'linux_env/tools/clipboard-copy')

    def test_native_vscode_merge_preserves_settings(self):
        for target, relative in [('linux', '.config/Code/User/settings.json'), ('macos', 'Library/Application Support/Code/User/settings.json')]:
            path = self.home / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps({'editor.fontSize': 17, 'workbench.colorCustomizations': {'unrelated.color': '#ffffff'}}))
            command = [sys.executable, str(REPO / 'linux_env/tools/apply-terminal-look.py'), '--home', str(self.home), '--platform', target]
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
            result = json.loads(path.read_text())
            self.assertEqual(result['editor.fontSize'], 17)
            self.assertEqual(result['workbench.colorCustomizations']['unrelated.color'], '#ffffff')
            self.assertEqual(result['workbench.colorCustomizations']['terminal.background'], '#34465f')
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
            backups = list((self.home / '.local/state/space/backups').glob('*/' + relative))
            self.assertEqual(len(backups), 1)

    def test_generated_profiles(self):
        subprocess.run([sys.executable, str(REPO / 'linux_env/tools/render-terminal-profiles.py'), '--check'], check=True, stdout=subprocess.DEVNULL)
        terminal = plistlib.loads((REPO / 'mac_env/config/Space Navy.terminal').read_bytes())
        archive = plistlib.loads(terminal['BackgroundColor'])
        rgb = list(map(float, archive['$objects'][1]['NSRGB'].rstrip(b'\0').split()))
        for actual, expected in zip(rgb, [52 / 255, 70 / 255, 95 / 255]):
            self.assertAlmostEqual(actual, expected, places=8)
        profile = json.loads((REPO / 'mac_env/config/iterm2-space.json').read_text())['Profiles'][0]
        self.assertEqual(profile['Name'], 'Space Navy')
        self.assertEqual(len([k for k in profile if k.startswith('Ansi ')]), 16)

    def test_clipboard_backends_preserve_bytes(self):
        binary = self.home / 'mock-bin'
        binary.mkdir()
        copied = self.home / 'copied'
        payload = 'café “quotes” ✓\nsecond line\n'.encode()
        for system, backend, environ in [('Darwin', 'pb', {}), ('Linux', 'wl', {'WAYLAND_DISPLAY': 'test'}), ('Linux', 'x', {'DISPLAY': ':test'})]:
            for path in binary.iterdir():
                path.unlink()
            def mock(name, body):
                p = binary / name
                p.write_text('#!/bin/sh\n' + body + '\n')
                p.chmod(0o755)
            mock('uname', f'printf "%s\\n" {system}')
            # Use stdin/stdout only; no desktop clipboard is touched.
            if backend == 'pb':
                mock('pbcopy', 'cat > "$SPACE_COPIED"')
                mock('pbpaste', 'cat "$SPACE_COPIED"')
            elif backend == 'wl':
                mock('wl-copy', 'cat > "$SPACE_COPIED"')
                mock('wl-paste', '[ "$1" = --no-newline ] || exit 2; cat "$SPACE_COPIED"')
            else:
                mock('xclip', 'case "$*" in *-in) cat > "$SPACE_COPIED";; *-out) cat "$SPACE_COPIED";; *) exit 2;; esac')
            env = {k: v for k, v in os.environ.items() if k not in ['DISPLAY', 'WAYLAND_DISPLAY']}
            env.update(environ, PATH=str(binary) + ':/usr/bin:/bin', SPACE_COPIED=str(copied))
            subprocess.run([str(REPO / 'linux_env/tools/clipboard-copy')], input=payload, check=True, env=env)
            output = subprocess.check_output([str(REPO / 'linux_env/tools/clipboard-paste')], env=env)
            self.assertEqual(output, payload, backend)


if __name__ == '__main__':
    unittest.main()
