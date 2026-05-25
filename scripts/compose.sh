#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

if [ -z "${COMPOSE_PROJECT_NAME:-}" ]; then
  COMPOSE_PROJECT_NAME="${MARKETPLACE_EVM_STACK_PROJECT:-marketplace-evm-stack}"
fi

DATA_DIR="${MARKETPLACE_EVM_STACK_DATA_DIR:-$REPO_ROOT/data}"
case "$DATA_DIR" in
  /*) ;;
  *) DATA_DIR="$REPO_ROOT/$DATA_DIR" ;;
esac

export COMPOSE_PROJECT_NAME
export MARKETPLACE_EVM_STACK_DATA_DIR="$DATA_DIR"

cd "$REPO_ROOT"
exec docker compose --env-file ./.env -f compose.yaml "$@"
