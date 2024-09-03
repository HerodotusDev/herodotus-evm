![](/banner.png)

### Herodotus EVM Smart Contracts

Herodotus contracts for EVM chains.

# Prerequisites:

- Git
- Node.js (^18.0)
- npm
- pnpm
- Foundry
- Solc

## Running Locally

Create a `.env` file based on `.env.example`, and then run:

```bash
git clone git@github.com:HerodotusDev/herodotus-evm.git
cd herodotus-evm

# If you do not have pnpm, run `npm install -g pnpm`
# Install dependencies
pnpm install

# Install libraries
forge install

# Running tests requires .env to be configured
forge test
```

## Contracts Overview

- CommitmentsInbox: receives block commitments from the origin chain using either the native messaging system or an optimistic relayer.

- HeadersProcessor: processes block headers from the origin chain and stores them in a Merkle Mountain Range tree where the accumulation happens on-chain.

- FactsRegistry: stores facts (e.g., nonces, balances, code hashes, storage hashes, etc.) for each proven origin chain account.

Note: currently, the origin chain is Ethereum L1 (Sepolia on testnet and Mainnet on mainnet).
However, the contracts are designed to be chain-agnostic and can be used with any EVM-compatible chain.

## Deployed Contracts

- [Deployed Contracts Addresses](https://docs.herodotus.dev/herodotus-docs/developers/contract-addresses)

## Deployment

`pnpm run deploy`

## Documentation

Here are some useful links for further reading:

- [Herodotus Documentation](https://docs.herodotus.dev)
- [Herodotus Builder Guide](https://herodotus.notion.site/herodotus/Herodotus-Hands-On-Builder-Guide-5298b607069f4bcfba9513aa75ee74d4)

## License

Copyright 2023 - Herodotus Dev Ltd
