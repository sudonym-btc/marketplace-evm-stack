#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

absolute_path() {
  value="$1"
  case "$value" in
    /*) printf '%s\n' "$value" ;;
    *) printf '%s\n' "$2/$value" ;;
  esac
}

cleanup_shared_bitcoin_volume() {
  if [ "${MARKETPLACE_EVM_USE_SHARED_BITCOIN:-0}" != "1" ]; then
    return 0
  fi

  repo_root="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
  project="${COMPOSE_PROJECT_NAME:-${MARKETPLACE_EVM_STACK_PROJECT:-marketplace-evm-stack}}"
  volume="${project}_bitcoin-data"
  desired="$(absolute_path "${MARKETPLACE_SHARED_BITCOIN_DATA_DIR:-../../data/marketplace/bitcoind}" "$repo_root")"
  current="$(docker volume inspect "$volume" --format '{{ index .Options "device" }}' 2>/dev/null || true)"

  if [ -n "$current" ] && [ "$current" != "$desired" ]; then
    echo "Removing stale $volume bind target: $current"
    docker volume rm "$volume" >/dev/null
  fi
}

"$SCRIPT_DIR/ensure-data-dirs.sh"
cleanup_shared_bitcoin_volume
exec "$SCRIPT_DIR/compose.sh" up -d --remove-orphans "$@"
