import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.ARBITRUM_PRIVATE_KEY || "";
const CHAINID = process.env.L1_SEPOLIA_CHAINID || "";

if (!PRIVATE_KEY) {
  throw new Error("ARBITRUM_PRIVATE_KEY is not set in .env");
}
if (!CHAINID) {
  throw new Error("L1_SEPOLIA_CHAINID is not set in .env");
}

export async function main() {
  // deploy SimpleMessagesInbox
  const SimpleMessagesInbox = await hre.ethers.getContractFactory(
    "SimpleMessagesInbox",
  );
  const simpleMessagesInbox = await SimpleMessagesInbox.deploy();
  const simpleMessagesInboxAddr = await simpleMessagesInbox.getAddress();
  await simpleMessagesInbox.waitForDeployment();
  console.log("Deployed SimpleMessagesInbox at:", simpleMessagesInboxAddr);

  // deploy HeaderStore
  const HeadersStore = await hre.ethers.getContractFactory("HeadersStore");
  const headersStore = await HeadersStore.deploy(simpleMessagesInboxAddr);
  const headersStoreAddr = await headersStore.getAddress();
  await headersStore.waitForDeployment();
  console.log("Deployed HeadersStore at:", headersStoreAddr);

  // deploy FactsRegistry
  const FactsRegistry = await hre.ethers.getContractFactory("FactsRegistry");
  const factsRegistry = await FactsRegistry.deploy(headersStoreAddr);
  const factsRegistryAddr = await factsRegistry.getAddress();
  await factsRegistry.waitForDeployment();
  console.log("Deployed FactsRegistry at:", factsRegistryAddr);

  // set SimpleMessagesInbox variables
  await simpleMessagesInbox.setHeadersStore(headersStoreAddr);
  await simpleMessagesInbox.setMessagesOriginChainId(CHAINID);
  // setCrossDomainMsgSender will be called at step 3

  // verify SimpleMessagesInbox
  await hre.run("verify:verify", {
    address: simpleMessagesInboxAddr,
    constructorArguments: [],
    force: true,
  });

  // verify HeadersStore
  await hre.run("verify:verify", {
    address: headersStoreAddr,
    constructorArguments: [simpleMessagesInboxAddr],
    force: true,
  });

  // verify FactsRegistry
  await hre.run("verify:verify", {
    address: factsRegistryAddr,
    constructorArguments: [headersStoreAddr],
    force: true,
  });

  console.log(
    "===============================================================",
  );
  console.log("HeadersStore:", headersStoreAddr);
  console.log("FactsRegistry:", factsRegistryAddr);
  console.log("SimpleMessagesInbox:", simpleMessagesInboxAddr);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
