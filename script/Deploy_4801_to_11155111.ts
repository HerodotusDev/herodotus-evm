import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const l2OutputOracle = process.env.WORLD_CHAIN_SEPOLIA_L2_OUTPUT_ORACLE || "";
const messagesOriginChainId = process.env.L1_SEPOLIA_CHAINID || "";
const fetchingChainId = process.env.WORLD_CHAIN_SEPOLIA_CHAINID || "";
const aggregatorsFactory = process.env.L1_SEPOLIA_AGGREGATORS_FACTORY || "";

if (!l2OutputOracle) {
  throw new Error("WORLD_CHAIN_SEPOLIA_L2_OUTPUT_ORACLE is not set in .env");
}
if (!messagesOriginChainId) {
  throw new Error("L1_SEPOLIA_CHAINID is not set in .env");
}
if (!fetchingChainId) {
  throw new Error("WORLD_CHAIN_SEPOLIA_CHAINID is not set in .env");
}
if (!aggregatorsFactory) {
  throw new Error("L1_SEPOLIA_AGGREGATORS_FACTORY is not set in .env");
}

export async function main() {
  // deploy SimpleMessagesInbox
  const SimpleMessagesInbox = await hre.ethers.getContractFactory(
    "SimpleMessagesInbox",
  );
  const simpleMessagesInbox = await SimpleMessagesInbox.deploy();
  const simpleMessagesInboxAddress = await simpleMessagesInbox.getAddress();
  await simpleMessagesInbox.waitForDeployment();
  console.log("Deployed SimpleMessagesInbox at:", simpleMessagesInboxAddress);

  // deploy HeaderStore
  const HeadersStore = await hre.ethers.getContractFactory("HeadersStore");
  const headersStore = await HeadersStore.deploy(simpleMessagesInboxAddress);
  const headersStoreAddress = await headersStore.getAddress();
  await headersStore.waitForDeployment();
  console.log("Deployed HeadersStore at:", headersStoreAddress);

  // deploy FactsRegistry
  const FactsRegistry = await hre.ethers.getContractFactory("FactsRegistry");
  const factsRegistry = await FactsRegistry.deploy(headersStoreAddress);
  const factsRegistryAddress = await factsRegistry.getAddress();
  await factsRegistry.waitForDeployment();
  console.log("Deployed FactsRegistry at:", factsRegistryAddress);

  // set SimpleMessagesInbox variables
  await simpleMessagesInbox.setHeadersStore(headersStoreAddress);
  await simpleMessagesInbox.setMessagesOriginChainId(messagesOriginChainId);
  // setCrossDomainMsgSender will be called at after L1ToL1MessagesSender deployment

  // deploy OpStackParentHashesFetcher
  const OpStackParentHashesFetcher = await hre.ethers.getContractFactory(
    "OpStackParentHashesFetcher",
  );
  const opStackParentHashesFetcher = await OpStackParentHashesFetcher.deploy(
    l2OutputOracle,
    fetchingChainId,
  );
  const opStackParentHashesFetcherAddress =
    await opStackParentHashesFetcher.getAddress();
  await opStackParentHashesFetcher.waitForDeployment();
  console.log(
    "Deployed OpStackParentHashesFetcher at:",
    opStackParentHashesFetcherAddress,
  );

  // deploy L1ToL1MessagesSender
  const L1ToL1MessagesSender = await hre.ethers.getContractFactory(
    "L1ToL1MessagesSender",
  );
  const l1ToL1MessagesSender = await L1ToL1MessagesSender.deploy(
    aggregatorsFactory,
    opStackParentHashesFetcherAddress,
    simpleMessagesInboxAddress,
  );
  const l1ToL1MessagesSenderAddress = await l1ToL1MessagesSender.getAddress();
  await l1ToL1MessagesSender.waitForDeployment();
  console.log("Deployed L1ToL1MessagesSender at:", l1ToL1MessagesSenderAddress);

  // set crossDomainMsgSender of SimpleMessagesInbox
  const tx = await simpleMessagesInbox.setCrossDomainMsgSender(
    l1ToL1MessagesSenderAddress,
  );
  await tx.wait();
  console.log(
    `crossDomainMsgSender of SimpleMessagesInbox(${simpleMessagesInboxAddress}) has been set to ${l1ToL1MessagesSenderAddress}`,
  );

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

  console.log(
    "===============================================================",
  );
  console.log("HeadersStore:", headersStoreAddress);
  console.log("FactsRegistry:", factsRegistryAddress);
  console.log("SimpleMessagesInbox:", simpleMessagesInboxAddress);
  console.log("OpStackParentHashesFetcher:", opStackParentHashesFetcherAddress);
  console.log("L1ToL1MessagesSender:", l1ToL1MessagesSenderAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
