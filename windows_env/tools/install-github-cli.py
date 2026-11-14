#!/usr/bin/env python3
"""Install/update the official Linux GitHub CLI without sudo; verify its SHA-256."""
import hashlib
import json
from pathlib import Path
import platform
import shutil
import tarfile
import tempfile
import urllib.request

arch = {'x86_64': 'amd64', 'aarch64': 'arm64'}.get(platform.machine())
if not arch:
    raise SystemExit('Unsupported architecture: ' + platform.machine())
with urllib.request.urlopen('https://api.github.com/repos/cli/cli/releases/latest', timeout=30) as response:
    release = json.load(response)
version = release['tag_name'].removeprefix('v')
name = f'gh_{version}_linux_{arch}.tar.gz'
assets = {item['name']: item['browser_download_url'] for item in release['assets']}
with tempfile.TemporaryDirectory() as tmp:
    archive = Path(tmp) / name
    with urllib.request.urlopen(assets[name], timeout=60) as src, archive.open('wb') as out:
        shutil.copyfileobj(src, out)
    with urllib.request.urlopen(assets[f'gh_{version}_checksums.txt'], timeout=30) as response:
        checks = response.read().decode()
    expected = next(line.split()[0] for line in checks.splitlines() if line.split()[-1] == name)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
        raise SystemExit('SHA-256 verification failed; nothing installed')
    dest = Path.home() / '.local/bin/gh'
    dest.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive) as tar, tempfile.NamedTemporaryFile(dir=dest.parent, prefix='.gh-', delete=False) as out:
        staging = Path(out.name)
        try:
            with tar.extractfile(f'gh_{version}_linux_{arch}/bin/gh') as src:
                shutil.copyfileobj(src, out)
            out.flush()
            staging.chmod(0o755)
            staging.replace(dest)
        finally:
            staging.unlink(missing_ok=True)
print(f'Installed GitHub CLI {version}: {dest} (SHA-256 verified)')
