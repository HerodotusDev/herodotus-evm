import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.APE_CHAIN_PRIVATE_KEY || "";
const CHAINID = process.env.L1_SEPOLIA_CHAINID || "";
const crossDomainMsgSenderAddress = process.env.DEPLOYED_L2_MSG_FORWARDER || "";

if (!PRIVATE_KEY) {
  throw new Error("APE_CHAIN_PRIVATE_KEY is not set in .env");
}
if (!CHAINID) {
  throw new Error("L1_SEPOLIA_CHAINID is not set in .env");
}
if (!crossDomainMsgSenderAddress) {
  throw new Error("DEPLOYED_L2_MSG_FORWARDER is not set in .env");
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

  const aliasedAddress =
    "0x" +
    (
      (BigInt(crossDomainMsgSenderAddress) +
        BigInt("0x1111000000000000000000000000000000001111")) %
      BigInt("0x10000000000000000000000000000000000000000")
    )
      .toString(16)
      .padStart(40, "0");

  await simpleMessagesInbox.setCrossDomainMsgSender(aliasedAddress);

  // verify SimpleMessagesInbox
  await hre
    .run("verify:verify", {
      address: simpleMessagesInboxAddr,
      constructorArguments: [],
      force: true,
    })
    .catch((error) => {
      console.error("Verification of SimpleMessagesInbox failed:", error);
    });

  // verify HeadersStore
  await hre
    .run("verify:verify", {
      address: headersStoreAddr,
      constructorArguments: [simpleMessagesInboxAddr],
      force: true,
    })
    .catch((error) => {
      console.error("Verification of HeadersStore failed:", error);
    });

  // verify FactsRegistry
  await hre
    .run("verify:verify", {
      address: factsRegistryAddr,
      constructorArguments: [headersStoreAddr],
      force: true,
    })
    .catch((error) => {
      console.error("Verification of FactsRegistry failed:", error);
    });

  console.log(
    "===============================================================",
  );
  console.log("HeadersStore:", headersStoreAddr);
  console.log("FactsRegistry:", factsRegistryAddr);
  console.log("SimpleMessagesInbox:", simpleMessagesInboxAddr);
  console.log(
    `crossDomainMsgSender of SimpleMessagesInbox(${simpleMessagesInboxAddr}) has been set to ${aliasedAddress} (aliased from ${crossDomainMsgSenderAddress})`,
  );
  console.log(
    "===============================================================",
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
