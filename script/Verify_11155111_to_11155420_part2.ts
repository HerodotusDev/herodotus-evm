import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const l2Target = process.env.OP_MESSAGES_INBOX || "";
const crossDomainMsgSender =
  process.env.OPTIMISM_SEPOLIA_CROSS_DOMAIN_MESSENGER || "";
const nativeParentHashesFetcherAddress =
  process.env.NATIVE_PARENT_HASHES_FETCHER || "";
const l1ToOptimismMessagesSenderAddress =
  process.env.L1_TO_OPTIMISM_MESSAGES_SENDER || "";

if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}
if (!crossDomainMsgSender) {
  throw new Error("OPTIMISM_SEPOLIA_CROSS_DOMAIN_MESSENGER is not set in .env");
}
if (!l2Target) {
  throw new Error("OP_MESSAGES_INBOX is not set in .env");
}
if (!nativeParentHashesFetcherAddress) {
  throw new Error("NATIVE_PARENT_HASHES_FETCHER is not set");
}
if (!l1ToOptimismMessagesSenderAddress) {
  throw new Error("L1_TO_OPTIMISM_MESSAGES_SENDER is not set");
}

export async function main() {
  // verify NativeParentHashesFetcher
  await hre.run("verify:verify", {
    address: nativeParentHashesFetcherAddress,
    constructorArguments: [],
    force: true,
  });

  // verify L1ToOptimismMessagesSender
  await hre.run("verify:verify", {
    address: l1ToOptimismMessagesSenderAddress,
    constructorArguments: [
      aggregatorsFactory,
      nativeParentHashesFetcherAddress,
      l2Target,
      crossDomainMsgSender,
    ],
    force: true,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
