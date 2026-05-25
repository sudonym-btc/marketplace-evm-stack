#!/usr/bin/env sh
set -eu

CONFIG_FILE="${CONFIG_FILE:-/data/config/marketplace-evm-stack.json}"
ARBITRUM_RPC="${ARBITRUM_RPC:-http://anvil-arbitrum:8545}"
ROOTSTOCK_RPC="${ROOTSTOCK_RPC:-http://anvil:8545}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Missing stack config: $CONFIG_FILE" >&2
  exit 1
fi

ARBITRUM_CHAIN_ID="$(cast chain-id --rpc-url "$ARBITRUM_RPC" | tr -d '[:space:]')"
ROOTSTOCK_CHAIN_ID="$(cast chain-id --rpc-url "$ROOTSTOCK_RPC" | tr -d '[:space:]')"

if [ "$ARBITRUM_CHAIN_ID" != "412346" ]; then
  echo "Unexpected Arbitrum chain id: $ARBITRUM_CHAIN_ID" >&2
  exit 1
fi

if [ "$ROOTSTOCK_CHAIN_ID" != "33" ]; then
  echo "Unexpected Rootstock chain id: $ROOTSTOCK_CHAIN_ID" >&2
  exit 1
fi

MULTI_ESCROW_ADDRESS="$(sed -n '/"multiEscrow"/,/}/s/.*"address": "\([^"]*\)".*/\1/p' "$CONFIG_FILE" | head -1)"
if [ -z "$MULTI_ESCROW_ADDRESS" ]; then
  echo "Could not read MultiEscrow address from $CONFIG_FILE" >&2
  exit 1
fi

CODE="$(cast code --rpc-url "$ARBITRUM_RPC" "$MULTI_ESCROW_ADDRESS" | tr -d '[:space:]')"
if [ -z "$CODE" ] || [ "$CODE" = "0x" ]; then
  echo "Missing MultiEscrow code at $MULTI_ESCROW_ADDRESS" >&2
  exit 1
fi

echo "marketplace-evm stack ready"

