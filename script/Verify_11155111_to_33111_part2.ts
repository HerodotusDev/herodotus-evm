import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const apeChainMessageForwarderAddr =
  process.env.APE_CHAIN_MESSAGE_FORWARDER || "";
const apeChainInbox = process.env.APE_CHAIN_SEPOLIA_INBOX || "";
const apeCoin = process.env.APE_CHAIN_SEPOLIA_ARBITRUM_APE_COIN || "";

if (!apeChainMessageForwarderAddr) {
  throw new Error("APE_CHAIN_MESSAGE_FORWARDER is not set in .env");
}
if (!apeChainInbox) {
  throw new Error("APE_CHAIN_SEPOLIA_INBOX is not set in .env");
}
if (!apeCoin) {
  throw new Error("APE_CHAIN_SEPOLIA_ARBITRUM_APE_COIN is not set in .env");
}

export async function main() {
  // verify ApeChainMessageForwarder
  await hre
    .run("verify:verify", {
      address: apeChainMessageForwarderAddr,
      constructorArguments: [apeChainInbox, apeCoin],
      force: true,
    })
    .catch((error) => {
      console.error("Verification of ApeChainMessageForwarder failed:", error);
    });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
