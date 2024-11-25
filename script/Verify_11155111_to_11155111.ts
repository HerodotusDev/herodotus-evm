import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const simpleMessagesInboxAddress = process.env.SIMPLE_MESSAGES_INBOX || "";
const headersStoreAddress = process.env.HEADERS_STORE || "";
const factsRegistryAddress = process.env.FACTS_REGISTRY || "";
const nativeParentHashesFetcherAddress =
  process.env.NATIVE_PARENT_HASHES_FETCHER || "";
const l1ToL1MessagesSenderAddress = process.env.L1_TO_L1_MESSAGES_SENDER || "";

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
if (!nativeParentHashesFetcherAddress) {
  throw new Error("NATIVE_PARENT_HASHES_FETCHER is not set");
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

  // verify NativeParentHashesFetcher
  await hre.run("verify:verify", {
    address: nativeParentHashesFetcherAddress,
    constructorArguments: [],
    force: true,
  });

  // verify L1ToL1MessagesSender
  await hre.run("verify:verify", {
    address: l1ToL1MessagesSenderAddress,
    constructorArguments: [
      aggregatorsFactory,
      nativeParentHashesFetcherAddress,
      simpleMessagesInboxAddress,
    ],
    force: true,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
