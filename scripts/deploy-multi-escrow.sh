#!/usr/bin/env sh
set -eu

ARBITRUM_RPC="${ARBITRUM_RPC:-http://anvil-arbitrum:8545}"
HOST_ARBITRUM_RPC="${HOST_ARBITRUM_RPC:-http://127.0.0.1:8546}"
ROOTSTOCK_RPC="${ROOTSTOCK_RPC:-http://anvil:8545}"
HOST_ROOTSTOCK_RPC="${HOST_ROOTSTOCK_RPC:-http://127.0.0.1:8545}"
BOLTZ_API_URL="${BOLTZ_API_URL:-http://127.0.0.1:9001/v2}"
BOLTZ_CONTAINER_API_URL="${BOLTZ_CONTAINER_API_URL:-http://boltz-backend-nginx:9001/v2}"
CONTRACTS_DIR="${CONTRACTS_DIR:-/contracts}"
ARTIFACT="$CONTRACTS_DIR/artifacts/MultiEscrow.json"
CONFIG_DIR="${CONFIG_DIR:-/data/config}"
TOKEN_MANIFEST="${TOKEN_MANIFEST:-/data/arbitrum/token-addresses.json}"
DEPLOYER_PRIVATE_KEY="${MULTI_ESCROW_DEPLOYER_PRIVATE_KEY:-0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a}"
EXPECTED_MULTI_ESCROW_ADDRESS="${EXPECTED_MULTI_ESCROW_ADDRESS:-0x663f3ad617193148711d28f5334ee4ed07016602}"

mkdir -p "$CONFIG_DIR"

echo "Waiting for Arbitrum RPC..."
until cast chain-id --rpc-url "$ARBITRUM_RPC" >/dev/null 2>&1; do
  sleep 0.5
done

BYTECODE="$(sed -n 's/^[[:space:]]*"bytecode": "\(0x[0-9a-fA-F]*\)".*/\1/p' "$ARTIFACT" | head -1)"

if [ -z "$BYTECODE" ]; then
  echo "Could not read MultiEscrow bytecode from $ARTIFACT" >&2
  exit 1
fi

EXISTING_CODE="$(cast code --rpc-url "$ARBITRUM_RPC" "$EXPECTED_MULTI_ESCROW_ADDRESS" 2>/dev/null | tr -d '[:space:]' || true)"
if [ -n "$EXISTING_CODE" ] && [ "$EXISTING_CODE" != "0x" ]; then
  MULTI_ESCROW_ADDRESS="$EXPECTED_MULTI_ESCROW_ADDRESS"
  echo "MultiEscrow already deployed at $MULTI_ESCROW_ADDRESS"
else
  echo "Deploying MultiEscrow..."
  DEPLOY_OUTPUT="$(cast send --rpc-url "$ARBITRUM_RPC" --private-key "$DEPLOYER_PRIVATE_KEY" --create "$BYTECODE" --json 2>&1)"
  MULTI_ESCROW_ADDRESS="$(echo "$DEPLOY_OUTPUT" | sed -n 's/.*"contractAddress":"\([^"]*\)".*/\1/p' | head -1)"

  if [ -z "$MULTI_ESCROW_ADDRESS" ]; then
    echo "Failed to extract MultiEscrow address from deployment output" >&2
    echo "$DEPLOY_OUTPUT" >&2
    exit 1
  fi
fi

CODE="$(cast code --rpc-url "$ARBITRUM_RPC" "$MULTI_ESCROW_ADDRESS" | tr -d '[:space:]')"
if [ -z "$CODE" ] || [ "$CODE" = "0x" ]; then
  echo "No runtime bytecode found at MultiEscrow address $MULTI_ESCROW_ADDRESS" >&2
  exit 1
fi
RUNTIME_HASH="0x$(printf '%s' "${CODE#0x}" | perl -ne 'print pack("H*", $_)' | sha256sum | awk '{print $1}')"

TBTC_ADDRESS="0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"
USDT_ADDRESS="0x712516e61C8B383dF4A63CFe83d7701Bce54B03e"

if [ -f "$TOKEN_MANIFEST" ]; then
  TBTC_ADDRESS="$(sed -n '/"tBTC"/,/}/s/.*"address": "\([^"]*\)".*/\1/p' "$TOKEN_MANIFEST" | head -1)"
  USDT_ADDRESS="$(sed -n '/"USDT"/,/}/s/.*"address": "\([^"]*\)".*/\1/p' "$TOKEN_MANIFEST" | head -1)"
fi

cat > "$CONFIG_DIR/contract-addresses.json" << JSON
{
  "regtest.412346": {
    "MultiEscrow": "$MULTI_ESCROW_ADDRESS"
  }
}
JSON

cat > "$CONFIG_DIR/marketplace-evm-stack.json" << JSON
{
  "version": 1,
  "chains": {
    "arbitrumRegtest": {
      "name": "Arbitrum Regtest",
      "chainId": 412346,
      "rpcUrl": "$HOST_ARBITRUM_RPC",
      "containerRpcUrl": "$ARBITRUM_RPC",
      "nativeToken": {
        "denomination": "ETH",
        "decimals": 18
      },
      "boltzCurrency": "ARB",
      "multiEscrow": {
        "address": "$MULTI_ESCROW_ADDRESS",
        "runtimeBytecodeHash": "$RUNTIME_HASH"
      },
      "tokens": {
        "TBTC": {
          "address": "$TBTC_ADDRESS",
          "denomination": "tBTC",
          "decimals": 18,
          "boltzCurrency": "tBTC"
        },
        "USDT": {
          "address": "$USDT_ADDRESS",
          "denomination": "USDT",
          "decimals": 6,
          "boltzCurrency": "USDT"
        }
      }
    },
    "rootstockRegtest": {
      "name": "Rootstock Regtest",
      "chainId": 33,
      "rpcUrl": "$HOST_ROOTSTOCK_RPC",
      "containerRpcUrl": "$ROOTSTOCK_RPC",
      "nativeToken": {
        "denomination": "RBTC",
        "decimals": 18
      },
      "boltzCurrency": "RBTC"
    }
  },
  "boltz": {
    "apiUrl": "$BOLTZ_API_URL",
    "containerApiUrl": "$BOLTZ_CONTAINER_API_URL"
  },
  "accounts": {
    "buyer": {
      "address": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "privateKey": "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    },
    "seller": {
      "address": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
      "privateKey": "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
    },
    "arbiter": {
      "address": "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
      "privateKey": "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
    }
  }
}
JSON

echo "MultiEscrow deployed at $MULTI_ESCROW_ADDRESS"
echo "Config written to $CONFIG_DIR/marketplace-evm-stack.json"
