import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.WORLD_CHAIN_PRIVATE_KEY || "";
const CHAINID = process.env.L1_SEPOLIA_CHAINID || "";

if (!PRIVATE_KEY) {
  throw new Error("WORLD_CHAIN_PRIVATE_KEY is not set in .env");
}
if (!CHAINID) {
  throw new Error("L1_SEPOLIA_CHAINID is not set in .env");
}

export async function main() {
  // deploy OpMessagesInbox
  const OpMessagesInbox =
    await hre.ethers.getContractFactory("OpMessagesInbox");
  const opMessagesInbox = await OpMessagesInbox.deploy();
  const opMessagesInboxAddr = await opMessagesInbox.getAddress();
  await opMessagesInbox.waitForDeployment();
  console.log("Deployed OpMessagesInbox at:", opMessagesInboxAddr);

  // deploy HeaderStore
  const HeadersStore = await hre.ethers.getContractFactory("HeadersStore");
  const headersStore = await HeadersStore.deploy(opMessagesInboxAddr);
  const headersStoreAddr = await headersStore.getAddress();
  await headersStore.waitForDeployment();
  console.log("Deployed HeadersStore at:", headersStoreAddr);

  // deploy FactsRegistry
  const FactsRegistry = await hre.ethers.getContractFactory("FactsRegistry");
  const factsRegistry = await FactsRegistry.deploy(headersStoreAddr);
  const factsRegistryAddr = await factsRegistry.getAddress();
  await factsRegistry.waitForDeployment();
  console.log("Deployed FactsRegistry at:", factsRegistryAddr);

  // set OpMessagesInbox variables
  await opMessagesInbox.setHeadersStore(headersStoreAddr);
  await opMessagesInbox.setMessagesOriginChainId(CHAINID);
  // setCrossDomainMsgSender will be called at step 3

  // verify OpMessagesInbox
  await hre.run("verify:verify", {
    address: opMessagesInboxAddr,
    constructorArguments: [],
    force: true,
  });

  // verify HeadersStore
  await hre.run("verify:verify", {
    address: headersStoreAddr,
    constructorArguments: [opMessagesInboxAddr],
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
  console.log("OpMessagesInbox:", opMessagesInboxAddr);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
