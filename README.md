### herodotus-evm

EVM contracts for Herodotus

# Prerequisites:

- Git

- Node.js

- Yarn

- Foundry

- Solc

## Getting Started

Create your `.env` file based on the `.env.example` file then run:

```bash
git clone git@github.com:HerodotusDev/herodotus-evm.git
cd herodotus-evm
yarn install
forge install # will ask for your GH username + personal access token (generate one on github >> settings > developer tools)
forge build
forge test
```
