#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
"$SCRIPT_DIR/ensure-data-dirs.sh"
exec "$SCRIPT_DIR/compose.sh" up -d --remove-orphans "$@"
