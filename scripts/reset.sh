#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${MARKETPLACE_EVM_STACK_DATA_DIR:-$REPO_ROOT/data}"

case "$DATA_DIR" in
  /*) ;;
  *) DATA_DIR="$REPO_ROOT/$DATA_DIR" ;;
esac

"$SCRIPT_DIR/down.sh" --volumes --remove-orphans
mkdir -p "$DATA_DIR"
find "$DATA_DIR" -mindepth 1 -type f ! -name .gitkeep -delete
find "$DATA_DIR" -mindepth 1 -type d -empty -delete
"$SCRIPT_DIR/ensure-data-dirs.sh"
