#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

absolute_path() {
  value="$1"
  case "$value" in
    /*) printf '%s\n' "$value" ;;
    *) printf '%s\n' "$REPO_ROOT/$value" ;;
  esac
}

wait_for_file() {
  path="$1"
  timeout="${2:-300}"
  deadline=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if [ -s "$path" ]; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for $path" >&2
  return 1
}

wait_for_healthy_service() {
  service="$1"
  timeout="${2:-300}"
  deadline=$((SECONDS + timeout))
  while [ "$SECONDS" -lt "$deadline" ]; do
    status="$("$SCRIPT_DIR/compose.sh" ps --format json "$service" 2>/dev/null || true)"
    if printf '%s\n' "$status" | grep -q '"State":"running"' &&
      printf '%s\n' "$status" | grep -q '"Health":"healthy"'; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for $service to become healthy" >&2
  return 1
}

"$SCRIPT_DIR/ensure-data-dirs.sh"

if ! "$SCRIPT_DIR/compose.sh" ps --services --status running | grep -qx boltz-backend-nginx; then
  "$SCRIPT_DIR/compose.sh" up -d --remove-orphans
fi

DATA_DIR="$(absolute_path "${MARKETPLACE_EVM_STACK_DATA_DIR:-data}")"
CONFIG_FILE="$DATA_DIR/config/marketplace-evm-stack.json"

wait_for_file "$CONFIG_FILE"
wait_for_healthy_service boltz-backend-nginx
wait_for_healthy_service alto
wait_for_healthy_service paymaster
"$SCRIPT_DIR/compose.sh" --profile default --profile tools run --rm --no-deps stack-ready
