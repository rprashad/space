#!/usr/bin/env python3
"""Install the Powerlevel10k MesloLGS NF fonts for the current user."""
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import urllib.parse
import urllib.request

font_dir = Path.home() / ('Library/Fonts' if platform.system() == 'Darwin' else '.local/share/fonts/space')
font_dir.mkdir(parents=True, exist_ok=True)
for style in ['Regular', 'Bold', 'Italic', 'Bold Italic']:
    name = f'MesloLGS NF {style}.ttf'
    dest = font_dir / name
    if dest.exists():
        continue
    url = 'https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/' + urllib.parse.quote(name)
    with tempfile.NamedTemporaryFile(dir=font_dir, delete=False) as out:
        staging = Path(out.name)
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                shutil.copyfileobj(response, out)
            out.flush()
            # A font download must have an sfnt/TrueType header, not an error page.
            if staging.read_bytes()[:4] not in [b'\x00\x01\x00\x00', b'OTTO', b'ttcf']:
                raise RuntimeError(f'Invalid font: {name}')
            staging.chmod(0o644)
            staging.replace(dest)
        finally:
            staging.unlink(missing_ok=True)
    print(f'Installed {dest}')
if shutil.which('fc-cache'):
    subprocess.run(['fc-cache', '-f', str(font_dir)], check=True)
