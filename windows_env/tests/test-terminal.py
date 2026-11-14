#!/usr/bin/env python3
"""Compatibility entrypoint for the shared terminal integration checks."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parents[2] / 'linux_env/tests/test-paste.py'), run_name='__main__')
