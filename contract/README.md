# Zent Contracts (Foundry)

## Setup

1. Copy `.env.example` to `.env` and fill in values (do not commit secrets):

```bash
cp .env.example .env
```

Example:

```bash
export KAIA_KAIROS_RPC_URL="https://<your-kairos-rpc>"
export KAIA_KAIROS_CHAIN_ID=1001
export DEPLOYER_PRIVATE_KEY=0x...
```

2. Install dependencies, build, and test:

```bash
cd packages/contract
forge install
forge build
forge test
```

3. Deploy to Kairos (KAIA testnet):

```bash
make deploy-kairos
```

Contracts target Solidity ^0.8.24 and are EVM-compatible with no chain-specific opcodes.
