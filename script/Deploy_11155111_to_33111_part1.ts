import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.ARBITRUM_PRIVATE_KEY || "";
const CHAINID = process.env.L1_SEPOLIA_CHAINID || "";
const apeChainInbox = process.env.APE_CHAIN_SEPOLIA_INBOX || "";
const apeCoin = process.env.APE_CHAIN_SEPOLIA_ARBITRUM_APE_COIN || "";

if (!PRIVATE_KEY) {
  throw new Error("ARBITRUM_PRIVATE_KEY is not set in .env");
}
if (!CHAINID) {
  throw new Error("L1_SEPOLIA_CHAINID is not set in .env");
}
if (!apeChainInbox) {
  throw new Error("APE_CHAIN_SEPOLIA_INBOX is not set in .env");
}
if (!apeCoin) {
  throw new Error("APE_CHAIN_SEPOLIA_ARBITRUM_APE_COIN is not set in .env");
}

export async function main() {
  // deploy ApeChainMessageForwarder
  const ApeChainMessageForwarder = await hre.ethers.getContractFactory(
    "ApeChainMessageForwarder",
  );
  const apeChainMessageForwarder = await ApeChainMessageForwarder.deploy(
    apeChainInbox,
    apeCoin,
  );
  const apeChainMessageForwarderAddr =
    await apeChainMessageForwarder.getAddress();
  await apeChainMessageForwarder.waitForDeployment();
  console.log(
    "Deployed ApeChainMessageForwarder at:",
    apeChainMessageForwarderAddr,
  );
  // setCrossDomainMsgSender will be called at step 4

  // verify ApeChainMessageForwarder
  await hre.run("verify:verify", {
    address: apeChainMessageForwarderAddr,
    constructorArguments: [apeChainInbox, apeCoin],
    force: true,
  });

  console.log(
    "===============================================================",
  );
  console.log("ApeChainMessageForwarder:", apeChainMessageForwarderAddr);
  console.log(
    "===============================================================",
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
