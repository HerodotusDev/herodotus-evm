import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.WORLD_CHAIN_PRIVATE_KEY || "";
const opMessagesInboxAddress = process.env.DEPLOYED_L2_INBOX || "";
const crossDomainMsgSenderAddress = process.env.DEPLOYED_L1_OUTBOX || "";

if (!PRIVATE_KEY) {
  throw new Error("WORLD_CHAIN_PRIVATE_KEY is not set in .env");
}
if (!opMessagesInboxAddress) {
  throw new Error("DEPLOYED_L2_INBOX is not set in .env");
}
if (!crossDomainMsgSenderAddress) {
  throw new Error("DEPLOYED_L1_OUTBOX is not set in .env");
}

export async function main() {
  // Call setCrossDomainMsgSender on OpMessagesInbox
  const opMessagesInbox = await hre.ethers.getContractAt(
    "OpMessagesInbox",
    opMessagesInboxAddress,
  );
  const tx = await opMessagesInbox.setCrossDomainMsgSender(
    crossDomainMsgSenderAddress,
  );
  await tx.wait();

  console.log(
    `crossDomainMsgSender of OpMessagesInbox(${opMessagesInboxAddress}) has been set to ${crossDomainMsgSenderAddress}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
