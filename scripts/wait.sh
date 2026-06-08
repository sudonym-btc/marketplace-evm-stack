#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
"$SCRIPT_DIR/ensure-data-dirs.sh"

if ! "$SCRIPT_DIR/compose.sh" ps --services --status running | grep -qx boltz-backend-nginx; then
  "$SCRIPT_DIR/compose.sh" up --wait --wait-timeout 300 --remove-orphans
fi

"$SCRIPT_DIR/compose.sh" up -d --wait --wait-timeout 300 --remove-orphans paymaster

"$SCRIPT_DIR/compose.sh" --profile default --profile tools run --rm --no-deps stack-ready
