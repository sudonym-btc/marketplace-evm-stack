# Marketplace EVM Stack

Standalone Docker stack for testing marketplace EVM drivers against the same
Boltz + EVM environment.

The stack is intentionally Nostr-agnostic and app-agnostic. It provides:

- Boltz regtest services
- Rootstock-style Anvil chain `33`
- Arbitrum-style Anvil chain `412346`
- Boltz EVM swap contracts
- mock `tBTC` and `USDT`
- Uniswap V3 routing contracts for Boltz rates
- `MultiEscrow` deployed from `@sudonym-btc/marketplace-evm-contracts` for escrow and auction bid locks
- local ERC-4337 account-abstraction services: Alto bundler and mock paymaster
- a standalone Boltz regtest Bitcoin node when run directly
- a generated JSON config consumed by TypeScript and Dart tests

## Usage

```sh
git submodule update --init --recursive
./scripts/up.sh
./scripts/wait.sh
```

The scripts run the standalone test instance with Compose project
`marketplace-evm-stack`, high host ports, and `./data` as the data directory.
They are convenience wrappers around the Compose file; the real lifecycle work
is done by Compose services and one-shot init containers.

The generated test config is written to:

```text
data/config/marketplace-evm-stack.json
```

The standalone stack uses fixed localhost ports by default:

- Arbitrum RPC: `http://127.0.0.1:18546`
- Arbitrum explorer: `http://127.0.0.1:15100`
- Rootstock RPC: `http://127.0.0.1:18545`
- Boltz API: `http://127.0.0.1:19001/v2`
- Bundler: `http://127.0.0.1:4337`
- Paymaster: `http://127.0.0.1:3010`

Consumer packages should point their integration tests at that file:

```sh
MARKETPLACE_EVM_STACK_CONFIG=/path/to/marketplace-evm-stack/data/config/marketplace-evm-stack.json
```

For the default standalone stack, consumers can also infer the config from the
default host ports and deterministic contract addresses.

## Running Two Stacks

Running a standalone test stack and a parent-project-included stack at the same time is
supported. The Compose file deliberately avoids a top-level project name, fixed
container names, and fixed global volume names.

The remaining shared host resources are published ports and the data directory.
Give each standalone stack its own project name, ports, and data directory:

```sh
MARKETPLACE_EVM_STACK_PROJECT=marketplace-evm-test \
MARKETPLACE_EVM_STACK_DATA_DIR=./data-test \
MARKETPLACE_EVM_ARBITRUM_RPC_PORT=28546 \
MARKETPLACE_EVM_ROOTSTOCK_RPC_PORT=28545 \
MARKETPLACE_EVM_BOLTZ_API_PORT=29001 \
./scripts/up.sh
```

When this Compose file is included by another project, the parent
Compose project namespaces containers, networks, and volumes. The parent project
only needs to choose non-conflicting host ports if it publishes the same
services as a running standalone test stack.

To stop the stack:

```sh
./scripts/down.sh
```

To remove generated chain data:

```sh
./scripts/reset.sh
```
