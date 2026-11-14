#!/bin/sh
# Compatibility entrypoint: explicit, backed-up install; never pull on shell startup.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec python3 "$script_dir/install-terminal.py" "$@"
