import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const l2Target = process.env.SIMPLE_MESSAGES_INBOX || "";
const arbitrumInbox = process.env.ARBITRUM_SEPOLIA_INBOX || "";
const nativeParentHashesFetcherAddress =
  process.env.NATIVE_PARENT_HASHES_FETCHER || "";
const l1ToArbitrumMessagesSenderAddress =
  process.env.L1_TO_ARBITRUM_MESSAGES_SENDER || "";

if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}
if (!arbitrumInbox) {
  throw new Error("ARBITRUM_SEPOLIA_INBOX is not set in .env");
}
if (!l2Target) {
  throw new Error("SIMPLE_MESSAGES_INBOX is not set in .env");
}
if (!nativeParentHashesFetcherAddress) {
  throw new Error("NATIVE_PARENT_HASHES_FETCHER is not set");
}
if (!l1ToArbitrumMessagesSenderAddress) {
  throw new Error("L1_TO_ARBITRUM_MESSAGES_SENDER is not set");
}

export async function main() {
  // verify NativeParentHashesFetcher
  await hre.run("verify:verify", {
    address: nativeParentHashesFetcherAddress,
    constructorArguments: [],
    force: true,
  });

  // verify L1ToArbitrumMessagesSender
  await hre.run("verify:verify", {
    address: l1ToArbitrumMessagesSenderAddress,
    constructorArguments: [
      aggregatorsFactory,
      nativeParentHashesFetcherAddress,
      l2Target,
      arbitrumInbox,
    ],
    force: true,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
