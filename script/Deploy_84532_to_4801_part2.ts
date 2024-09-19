import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const l2OutputOracle = process.env.BASE_SEPOLIA_L2_OUTPUT_ORACLE || "";
const chainId = process.env.BASE_SEPOLIA_CHAINID || "";
const aggregatorsFactory = process.env.BASE_SEPOLIA_AGGREGATORS_FACTORY || "";
const l2Target = process.env.DEPLOYED_L2_INBOX || "";
const crossDomainMsgSender =
  process.env.WORLD_CHAIN_SEPOLIA_CROSS_DOMAIN_MESSENGER || "";

if (!l2OutputOracle) {
  throw new Error("BASE_SEPOLIA_L2_OUTPUT_ORACLE is not set in .env");
}
if (!chainId) {
  throw new Error("BASE_SEPOLIA_CHAINID is not set in .env");
}
if (!aggregatorsFactory) {
  throw new Error("BASE_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
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
  // deploy OpStackParentHashesFetcher
  const OpStackParentHashesFetcher = await hre.ethers.getContractFactory(
    "OpStackParentHashesFetcher",
  );
  const opStackParentHashesFetcher = await OpStackParentHashesFetcher.deploy(
    l2OutputOracle,
    chainId,
  );
  const opStackParentHashesFetcherAddress =
    await opStackParentHashesFetcher.getAddress();
  await opStackParentHashesFetcher.waitForDeployment();
  console.log(
    "Deployed OpStackParentHashesFetcher at:",
    opStackParentHashesFetcherAddress,
  );

  // deploy L1ToOptimismMessagesSender
  const L1ToOptimismMessagesSender = await hre.ethers.getContractFactory(
    "L1ToOptimismMessagesSender",
  );
  const l1ToOptimismMessagesSender = await L1ToOptimismMessagesSender.deploy(
    aggregatorsFactory,
    opStackParentHashesFetcherAddress,
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

  // verify OpStackParentHashesFetcher
  await hre.run("verify:verify", {
    address: opStackParentHashesFetcherAddress,
    constructorArguments: [l2OutputOracle, chainId],
    force: true,
  });

  // verify L1ToOptimismMessagesSender
  await hre.run("verify:verify", {
    address: l1ToOptimismMessagesSenderAddress,
    constructorArguments: [
      aggregatorsFactory,
      opStackParentHashesFetcherAddress,
      l2Target,
      crossDomainMsgSender,
    ],
    force: true,
  });

  console.log(
    "===============================================================",
  );
  console.log("OpStackParentHashesFetcher:", opStackParentHashesFetcherAddress);
  console.log(
    "L1ToOptimismMessagesSenderAddress:",
    l1ToOptimismMessagesSenderAddress,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
