import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const simpleMessagesInboxAddress = process.env.SIMPLE_MESSAGES_INBOX || "";
const headersStoreAddress = process.env.HEADERS_STORE || "";
const factsRegistryAddress = process.env.FACTS_REGISTRY || "";
const opStackParentHashesFetcherAddress =
  process.env.OP_STACK_PARENT_HASHES_FETCHER || "";
const l1ToL1MessagesSenderAddress = process.env.L1_TO_L1_MESSAGES_SENDER || "";
const l2OutputOracle = process.env.WORLD_CHAIN_SEPOLIA_L2_OUTPUT_ORACLE || "";
const fetchingChainId = process.env.WORLD_CHAIN_SEPOLIA_CHAINID || "";

if (!l2OutputOracle) {
  throw new Error("WORLD_CHAIN_SEPOLIA_L2_OUTPUT_ORACLE is not set in .env");
}
if (!fetchingChainId) {
  throw new Error("WORLD_CHAIN_SEPOLIA_CHAINID is not set in .env");
}
if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}
if (!simpleMessagesInboxAddress) {
  throw new Error("SIMPLE_MESSAGES_INBOX is not set");
}
if (!headersStoreAddress) {
  throw new Error("HEADERS_STORE is not set");
}
if (!factsRegistryAddress) {
  throw new Error("FACTS_REGISTRY is not set");
}
if (!opStackParentHashesFetcherAddress) {
  throw new Error("OP_STACK_PARENT_HASHES_FETCHER is not set");
}
if (!l1ToL1MessagesSenderAddress) {
  throw new Error("L1_TO_L1_MESSAGES_SENDER is not set");
}

export async function main() {
  // verify SimpleMessagesInbox
  await hre.run("verify:verify", {
    address: simpleMessagesInboxAddress,
    constructorArguments: [],
    force: true,
  });

  // verify HeadersStore
  await hre.run("verify:verify", {
    address: headersStoreAddress,
    constructorArguments: [simpleMessagesInboxAddress],
    force: true,
  });

  // verify FactsRegistry
  await hre.run("verify:verify", {
    address: factsRegistryAddress,
    constructorArguments: [headersStoreAddress],
    force: true,
  });

  // verify OpStackParentHashesFetcher
  await hre.run("verify:verify", {
    address: opStackParentHashesFetcherAddress,
    constructorArguments: [l2OutputOracle, fetchingChainId],
    force: true,
  });

  // verify L1ToL1MessagesSender
  await hre.run("verify:verify", {
    address: l1ToL1MessagesSenderAddress,
    constructorArguments: [
      aggregatorsFactory,
      opStackParentHashesFetcherAddress,
      simpleMessagesInboxAddress,
    ],
    force: true,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
