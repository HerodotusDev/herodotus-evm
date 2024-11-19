import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const l2Target = process.env.DEPLOYED_L2_MSG_FORWARDER || "";
const l3Target = process.env.DEPLOYED_L3_INBOX || "";
const arbitrumInbox = process.env.ARBITRUM_SEPOLIA_INBOX || "";

if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}
if (!l2Target) {
  throw new Error("DEPLOYED_L2_MSG_FORWARDER is not set in .env");
}
if (!l3Target) {
  throw new Error("DEPLOYED_L3_INBOX is not set in .env");
}
if (!arbitrumInbox) {
  throw new Error("ARBITRUM_SEPOLIA_INBOX is not set in .env");
}

export async function main() {
  // deploy NativeParentHashesFetcher
  const NativeParentHashesFetcher = await hre.ethers.getContractFactory(
    "NativeParentHashesFetcher",
  );
  const nativeParentHashesFetcher = await NativeParentHashesFetcher.deploy();
  const nativeParentHashesFetcherAddress =
    await nativeParentHashesFetcher.getAddress();
  await nativeParentHashesFetcher.waitForDeployment();
  console.log(
    "Deployed NativeParentHashesFetcher at:",
    nativeParentHashesFetcherAddress,
  );

  // deploy L1ToApeChainMessagesSender
  const L1ToApeChainMessagesSender = await hre.ethers.getContractFactory(
    "L1ToApeChainMessagesSender",
  );
  const l1ToApeChainMessagesSender = await L1ToApeChainMessagesSender.deploy(
    aggregatorsFactory,
    nativeParentHashesFetcherAddress,
    l2Target,
    l3Target,
    arbitrumInbox,
  );
  const l1ToApeChainMessagesSenderAddress =
    await l1ToApeChainMessagesSender.getAddress();
  await l1ToApeChainMessagesSender.waitForDeployment();
  console.log(
    "Deployed L1ToApeChainMessagesSender at:",
    l1ToApeChainMessagesSenderAddress,
  );

  // verify NativeParentHashesFetcher
  await hre
    .run("verify:verify", {
      address: nativeParentHashesFetcherAddress,
      constructorArguments: [],
      force: true,
    })
    .catch((error) => {
      console.error("Verification of NativeParentHashesFetcher failed:", error);
    });

  // verify L1ToApeChainMessagesSender
  await hre
    .run("verify:verify", {
      address: l1ToApeChainMessagesSenderAddress,
      constructorArguments: [
        aggregatorsFactory,
        nativeParentHashesFetcherAddress,
        l2Target,
        l3Target,
        arbitrumInbox,
      ],
      force: true,
    })
    .catch((error) => {
      console.error(
        "Verification of L1ToApeChainMessagesSender failed:",
        error,
      );
    });

  console.log(
    "===============================================================",
  );
  console.log("NativeParentHashesFetcher:", nativeParentHashesFetcherAddress);
  console.log(
    "L1ToApeChainMessagesSenderAddress:",
    l1ToApeChainMessagesSenderAddress,
  );
  console.log(
    "===============================================================",
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
