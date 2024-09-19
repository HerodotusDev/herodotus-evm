import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const l2Target = process.env.DEPLOYED_L2_INBOX || "";
const crossDomainMsgSender =
  process.env.WORLD_CHAIN_SEPOLIA_CROSS_DOMAIN_MESSENGER || "";

if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}
if (!l2Target) {
  throw new Error("DEPLOYED_L2_INBOX is not set in .env");
}
if (!crossDomainMsgSender) {
  throw new Error(
    "WORLD_CHAIN_SEPOLIA_CROSS_DOMAIN_MESSENGER is not set in .env",
  );
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

  // deploy L1ToOptimismMessagesSender
  const L1ToOptimismMessagesSender = await hre.ethers.getContractFactory(
    "L1ToOptimismMessagesSender",
  );
  const l1ToOptimismMessagesSender = await L1ToOptimismMessagesSender.deploy(
    aggregatorsFactory,
    nativeParentHashesFetcherAddress,
    l2Target,
    crossDomainMsgSender,
  );
  const l1ToOptimismMessagesSenderAddress =
    await l1ToOptimismMessagesSender.getAddress();
  await l1ToOptimismMessagesSender.waitForDeployment();
  console.log(
    "Deployed L1ToOptimismMessagesSender at:",
    l1ToOptimismMessagesSenderAddress,
  );

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

  console.log(
    "===============================================================",
  );
  console.log("NativeParentHashesFetcher:", nativeParentHashesFetcherAddress);
  console.log(
    "L1ToOptimismMessagesSenderAddress:",
    l1ToOptimismMessagesSenderAddress,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
