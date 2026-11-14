#!/usr/bin/env python3
"""Exercise literal Unicode/multiline paste in real Zsh PTYs, outside/inside tmux.

Uses a private tmux socket and a fake clipboard; never alters the real clipboard.
"""
import os
from pathlib import Path
import pty
import platform
import select
import shlex
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[2]
PAYLOAD = 'café “quoted” ✓\nsecond line; $(must_not_execute)\n'


def wait_for(path, process=None):
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        if path.exists():
            return
        if process and process.poll() is not None:
            raise AssertionError('Shell exited early')
        time.sleep(.05)
    raise AssertionError(f'Timed out waiting for {path.name}')


def setup(result, ready):
    # A widget reads the edit buffer without executing the pasted content.
    return (f'function space_capture() {{ print -rn -- "$BUFFER" > {shlex.quote(str(result))}; BUFFER=""; zle reset-prompt; }}; '
            f'zle -N space_capture; bindkey "^X" space_capture; : > {shlex.quote(str(ready))}\n')


with tempfile.TemporaryDirectory(prefix='space-terminal-', dir='/tmp') as tmp:
    tmp = Path(tmp)
    # Installation is idempotent in a fresh home, including WSL overrides.
    stage = tmp / 'home'
    stage.mkdir()
    install = ['python3', str(REPO / 'linux_env/tools/install-terminal.py'), '--home', str(stage), '--platform', 'macos' if platform.system() == 'Darwin' else 'linux']
    subprocess.run(install, check=True, stdout=subprocess.DEVNULL)
    again = subprocess.check_output(install + ['--dry-run'], text=True)
    assert not again.strip(), again
    print('PASS: staged installation and idempotency')

    result, ready = tmp / 'direct-result', tmp / 'direct-ready'
    master, slave = pty.openpty()
    env = dict(os.environ, TERM='xterm-256color', HOME=str(stage), ZDOTDIR=str(stage))
    process = subprocess.Popen(['zsh', '-il'], stdin=slave, stdout=slave, stderr=slave, env=env, start_new_session=True)
    os.close(slave)
    try:
        os.write(master, setup(result, ready).encode())
        # Drain the PTY while shell startup and prompt rendering finish.
        deadline = time.monotonic() + 15
        while not ready.exists() and time.monotonic() < deadline:
            if select.select([master], [], [], .1)[0]:
                os.read(master, 65536)
        wait_for(ready, process)
        time.sleep(.2)
        os.write(master, b'\x1b[200~' + PAYLOAD.encode() + b'\x1b[201~\x18')
        wait_for(result, process)
        assert result.read_text() == PAYLOAD, repr(result.read_text())
        print('PASS: Zsh literal bracketed paste, Unicode, quotes, multiline')
    finally:
        process.kill()
        process.wait(timeout=5)
        os.close(master)

    socket = str(tmp / 'tmux.sock')
    tmux = ['tmux', '-S', socket]
    def run(*args, **kwargs):
        return subprocess.run(tmux + list(args), check=True, **kwargs)
    try:
        run('-f', str(REPO / 'linux_env/.tmux.conf'), 'new-session', '-d', '-s', 'paste-test', 'zsh -il', env=env)
        result, ready = tmp / 'tmux-result', tmp / 'tmux-ready'
        run('send-keys', '-t', 'paste-test:1.1', '-l', setup(result, ready).rstrip('\n'))
        run('send-keys', '-t', 'paste-test:1.1', 'Enter')
        wait_for(ready)
        fake = tmp / 'clipboard-home/.local/bin'
        fake.mkdir(parents=True)
        clipboard = tmp / 'clipboard'
        clipboard.write_text(PAYLOAD)
        fake_paste = fake / 'clipboard-paste'
        fake_paste.write_text('#!/bin/sh\ncat ' + shlex.quote(str(clipboard)) + '\n')
        fake_paste.chmod(0o755)
        test_env = dict(os.environ, HOME=str(tmp / 'clipboard-home'), TMUX=socket + ',0,0')
        subprocess.run([str(REPO / 'linux_env/tools/tmux-paste-clipboard'), 'paste-test:1.1'], env=test_env, check=True)
        run('send-keys', '-t', 'paste-test:1.1', 'C-x')
        wait_for(result)
        assert result.read_text() == PAYLOAD, repr(result.read_text())
        print('PASS: clipboard helper → tmux → Zsh; no added paste markers')
    finally:
        subprocess.run(tmux + ['kill-server'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
