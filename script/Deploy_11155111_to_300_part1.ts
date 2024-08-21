import { Wallet } from "zksync-ethers";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.ZKSYNC_PRIVATE_KEY || "";
const CHAINID = process.env.L1_SEPOLIA_CHAINID || "";

if (!PRIVATE_KEY) {
  throw new Error("ZKSYNC_PRIVATE_KEY is not set in .env");
}
if (!CHAINID) {
  throw new Error("L1_SEPOLIA_CHAINID is not set in .env");
}

export async function main() {
  const wallet = new Wallet(PRIVATE_KEY);
  const deployer = new Deployer(hre, wallet);

  // deploy SimpleMessagesInbox
  const simpleMessagesInbox = await deployer.deploy(
    await deployer.loadArtifact("SimpleMessagesInbox"),
    [],
  );
  const simpleMessagesInboxAddr = await simpleMessagesInbox.getAddress();
  await simpleMessagesInbox.waitForDeployment();
  console.log("Deployed SimpleMessagesInbox at:", simpleMessagesInboxAddr);

  // deploy HeaderStore
  const headersStore = await deployer.deploy(
    await deployer.loadArtifact("HeadersStore"),
    [simpleMessagesInboxAddr],
  );
  const headersStoreAddr = await headersStore.getAddress();
  await headersStore.waitForDeployment();
  console.log("Deployed HeadersStore at:", headersStoreAddr);

  // deploy FactsRegistry
  const factsRegistry = await deployer.deploy(
    await deployer.loadArtifact("FactsRegistry"),
    [headersStoreAddr],
  );
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
