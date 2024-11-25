import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const nativeParentHashesFetcherAddr =
  process.env.NATIVE_PARENT_HASHES_FETCHER || "";
const l1ToApeChainMessagesSenderAddr =
  process.env.L1_TO_APE_CHAIN_MESSAGES_SENDER || "";
const apeChainMessageForwarderAddr =
  process.env.APE_CHAIN_MESSAGE_FORWARDER || "";
const simpleMessageInboxAddr = process.env.SIMPLE_MESSAGES_INBOX || "";
const aggregatorsFactoryAddr = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const arbitrumInboxAddr = process.env.ARBITRUM_SEPOLIA_INBOX || "";

if (!nativeParentHashesFetcherAddr) {
  throw new Error("NATIVE_PARENT_HASHES_FETCHER is not set");
}
if (!l1ToApeChainMessagesSenderAddr) {
  throw new Error("L1_TO_APE_CHAIN_MESSAGES_SENDER is not set");
}
if (!apeChainMessageForwarderAddr) {
  throw new Error("APE_CHAIN_MESSAGE_FORWARDER is not set");
}
if (!simpleMessageInboxAddr) {
  throw new Error("SIMPLE_MESSAGES_INBOX is not set");
}
if (!aggregatorsFactoryAddr) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set");
}
if (!arbitrumInboxAddr) {
  throw new Error("ARBITRUM_SEPOLIA_INBOX is not set");
}

export async function main() {
  // verify NativeParentHashesFetcher
  await hre
    .run("verify:verify", {
      address: nativeParentHashesFetcherAddr,
      constructorArguments: [],
      force: true,
    })
    .catch((error) => {
      console.error("Verification of NativeParentHashesFetcher failed:", error);
    });

  // verify L1ToApeChainMessagesSender
  await hre
    .run("verify:verify", {
      address: l1ToApeChainMessagesSenderAddr,
      constructorArguments: [
        aggregatorsFactoryAddr,
        nativeParentHashesFetcherAddr,
        apeChainMessageForwarderAddr,
        simpleMessageInboxAddr,
        arbitrumInboxAddr,
      ],
      force: true,
    })
    .catch((error) => {
      console.error(
        "Verification of L1ToApeChainMessagesSender failed:",
        error,
      );
    });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
