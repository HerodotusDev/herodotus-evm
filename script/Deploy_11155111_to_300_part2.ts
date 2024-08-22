import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const l2Target = process.env.DEPLOYED_L2_INBOX || "";
const zksyncMailbox = process.env.ZKSYNC_SEPOLIA_MAILBOX || "";

if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}
if (!l2Target) {
  throw new Error("DEPLOYED_L2_INBOX is not set in .env");
}
if (!zksyncMailbox) {
  throw new Error("ZKSYNC_SEPOLIA_MAILBOX is not set in .env");
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

  // deploy L1ToZkSyncMessagesSender
  const L1ToZkSyncMessagesSender = await hre.ethers.getContractFactory(
    "L1ToZkSyncMessagesSender",
  );
  const l1ToZkSyncMessagesSender = await L1ToZkSyncMessagesSender.deploy(
    aggregatorsFactory,
    nativeParentHashesFetcherAddress,
    l2Target,
    zksyncMailbox,
  );
  const l1ToZkSyncMessagesSenderAddress =
    await l1ToZkSyncMessagesSender.getAddress();
  await l1ToZkSyncMessagesSender.waitForDeployment();
  console.log(
    "Deployed L1ToZkSyncMessagesSender at:",
    l1ToZkSyncMessagesSenderAddress,
  );

  // verify NativeParentHashesFetcher
  await hre.run("verify:verify", {
    address: nativeParentHashesFetcherAddress,
    constructorArguments: [],
    force: true,
  });

  // verify L1ToZkSyncMessagesSender
  await hre.run("verify:verify", {
    address: l1ToZkSyncMessagesSenderAddress,
    constructorArguments: [
      aggregatorsFactory,
      nativeParentHashesFetcherAddress,
      l2Target,
      zksyncMailbox,
    ],
    force: true,
  });

  console.log(
    "===============================================================",
  );
  console.log("NativeParentHashesFetcher:", nativeParentHashesFetcherAddress);
  console.log("L1ToZkSyncMessagesSender:", l1ToZkSyncMessagesSenderAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
