import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@nomicfoundation/hardhat-foundry";
import "@matterlabs/hardhat-zksync-verify";
import "@nomicfoundation/hardhat-verify";
import { config as dotEnvConfig } from "dotenv";

dotEnvConfig();

const config: HardhatUserConfig = {
  zksolc: {},
  solidity: {
    version: "0.8.20",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        details: {
          yulDetails: {
            optimizerSteps: "u",
          },
        },
      },
    },
  },
  paths: {
    sources: "src",
    deployPaths: "script",
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.L1_ETHERSCAN_API_KEY as string,
      zkSyncSepolia: process.env.ZKSYNC_ETHERSCAN_API_KEY as string,
      optimismSepolia: process.env.OPTIMISM_ETHERSCAN_API_KEY as string,
      arbitrumSepolia: process.env.ARBITRUM_ETHERSCAN_API_KEY as string,
      // worldChainSepolia: process.env.WORLD_CHAIN_ETHERSCAN_API_KEY as string,
    },
    customChains: [
      {
        network: "optimismSepolia",
        chainId: parseInt(process.env.OPTIMISM_SEPOLIA_CHAINID as string),
        urls: {
          apiURL: process.env.OPTIMISM_SEPOLIA_ETHERSCAN_API_URL as string,
          browserURL: process.env
            .OPTIMISM_SEPOLIA_ETHERSCAN_BROWSER_URL as string,
        },
      },
      {
        network: "arbitrumSepolia",
        chainId: parseInt(process.env.ARBITRUM_SEPOLIA_CHAINID as string),
        urls: {
          apiURL: process.env.ARBITRUM_SEPOLIA_ETHERSCAN_API_URL as string,
          browserURL: process.env
            .ARBITRUM_SEPOLIA_ETHERSCAN_BROWSER_URL as string,
        },
      },
      //? Verifying Probably does not work on World Chain yet
      // {
      //   network: "worldChainSepolia",
      //   chainId: parseInt(process.env.WORLD_CHAIN_SEPOLIA_CHAINID as string),
      //   urls: {
      //     apiURL: process.env.WORLD_CHAIN_SEPOLIA_ETHERSCAN_API_URL as string,
      //     browserURL: process.env
      //       .WORLD_CHAIN_SEPOLIA_ETHERSCAN_BROWSER_URL as string,
      //   },
      // },
    ],
  },
  defaultNetwork: "zkSyncSepolia",
  networks: {
    sepolia: {
      url: process.env.L1_SEPOLIA_RPC,
      accounts: [process.env.L1_PRIVATE_KEY as string],
    },
    zkSyncSepolia: {
      url: process.env.ZKSYNC_SEPOLIA_RPC,
      accounts: [process.env.ZKSYNC_PRIVATE_KEY as string],
      ethNetwork: process.env.L1_SEPOLIA_RPC,
      zksync: true,
      verifyURL: process.env.ZKSYNC_SEPOLIA_VERIFIER,
    },
    optimismSepolia: {
      url: process.env.OPTIMISM_SEPOLIA_RPC,
      accounts: [process.env.OPTIMISM_PRIVATE_KEY as string],
    },
    arbitrumSepolia: {
      url: process.env.ARBITRUM_SEPOLIA_RPC,
      accounts: [process.env.ARBITRUM_PRIVATE_KEY as string],
    },
    worldChainSepolia: {
      url: process.env.WORLD_CHAIN_SEPOLIA_RPC,
      accounts: [process.env.WORLD_CHAIN_PRIVATE_KEY as string],
    },
  },
};
export default config;
