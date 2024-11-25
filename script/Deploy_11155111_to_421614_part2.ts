import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";
const l2Target = process.env.DEPLOYED_L2_INBOX || "";
const arbitrumInbox = process.env.ARBITRUM_SEPOLIA_INBOX || "";

if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}
if (!l2Target) {
  throw new Error("DEPLOYED_L2_INBOX is not set in .env");
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

  // deploy L1ToArbitrumMessagesSender
  const L1ToArbitrumMessagesSender = await hre.ethers.getContractFactory(
    "L1ToArbitrumMessagesSender",
  );
  const l1ToArbitrumMessagesSender = await L1ToArbitrumMessagesSender.deploy(
    aggregatorsFactory,
    nativeParentHashesFetcherAddress,
    l2Target,
    arbitrumInbox,
  );
  const l1ToArbitrumMessagesSenderAddress =
    await l1ToArbitrumMessagesSender.getAddress();
  await l1ToArbitrumMessagesSender.waitForDeployment();
  console.log(
    "Deployed L1ToArbitrumMessagesSender at:",
    l1ToArbitrumMessagesSenderAddress,
  );

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

  console.log(
    "===============================================================",
  );
  console.log("NativeParentHashesFetcher:", nativeParentHashesFetcherAddress);
  console.log(
    "L1ToArbitrumMessagesSenderAddress:",
    l1ToArbitrumMessagesSenderAddress,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
