#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${MARKETPLACE_EVM_STACK_DATA_DIR:-$REPO_ROOT/data}"

case "$DATA_DIR" in
  /*) ;;
  *) DATA_DIR="$REPO_ROOT/$DATA_DIR" ;;
esac

for dir in \
  "$DATA_DIR/arbitrum" \
  "$DATA_DIR/config" \
  "$DATA_DIR/arkd" \
  "$DATA_DIR/boltz-client" \
  "$DATA_DIR/backend" \
  "$DATA_DIR/backend-nginx" \
  "$DATA_DIR/cln1" \
  "$DATA_DIR/cln2" \
  "$DATA_DIR/elements" \
  "$DATA_DIR/fulmine" \
  "$DATA_DIR/lnd1" \
  "$DATA_DIR/lnd2" \
  "$DATA_DIR/lnd3"
do
  mkdir -p "$dir"
  touch "$dir/.gitkeep"
done

if [ "${MARKETPLACE_EVM_USE_SHARED_BITCOIN:-0}" != "1" ]; then
  mkdir -p "$DATA_DIR/bitcoind"
  touch "$DATA_DIR/bitcoind/.gitkeep"
fi

touch "$DATA_DIR/.gitkeep"

copy_if_missing() {
  source_file="$1"
  target_file="$2"
  if [ -f "$source_file" ] && [ ! -f "$target_file" ]; then
    cp "$source_file" "$target_file"
  fi
}

copy_if_missing "$REPO_ROOT/dependencies/boltz-regtest/data/elements/elements.conf" "$DATA_DIR/elements/elements.conf"
copy_if_missing "$REPO_ROOT/dependencies/boltz-regtest/data/elements/elements.cookie" "$DATA_DIR/elements/elements.cookie"
copy_if_missing "$REPO_ROOT/dependencies/boltz-regtest/data/backend/seed.dat" "$DATA_DIR/backend/seed.dat"
copy_if_missing "$REPO_ROOT/dependencies/boltz-regtest/data/boltz-client/boltz.toml" "$DATA_DIR/boltz-client/boltz.toml"
cp "$REPO_ROOT/config/boltz.conf" "$DATA_DIR/backend/boltz.conf"
cp "$REPO_ROOT/config/boltz-nginx/default.conf" "$DATA_DIR/backend-nginx/default.conf"
