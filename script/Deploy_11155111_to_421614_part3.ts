import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.ARBITRUM_PRIVATE_KEY || "";
const simpleMessagesInboxAddress = process.env.DEPLOYED_L2_INBOX || "";
const crossDomainMsgSenderAddress = process.env.DEPLOYED_L1_OUTBOX || "";

if (!PRIVATE_KEY) {
  throw new Error("ARBITRUM_PRIVATE_KEY is not set in .env");
}
if (!simpleMessagesInboxAddress) {
  throw new Error("DEPLOYED_L2_INBOX is not set in .env");
}
if (!crossDomainMsgSenderAddress) {
  throw new Error("DEPLOYED_L1_OUTBOX is not set in .env");
}

export async function main() {
  // Call setCrossDomainMsgSender on SimpleMessagesInbox
  const simpleMessagesInbox = await hre.ethers.getContractAt(
    "SimpleMessagesInbox",
    simpleMessagesInboxAddress,
  );

  const aliasedAddress =
    "0x" +
    (
      (BigInt(crossDomainMsgSenderAddress) +
        BigInt("0x1111000000000000000000000000000000001111")) %
      BigInt("0x10000000000000000000000000000000000000000")
    ).toString(16);

  const tx = await simpleMessagesInbox.setCrossDomainMsgSender(aliasedAddress);
  await tx.wait();

  console.log(
    `crossDomainMsgSender of SimpleMessagesInbox(${simpleMessagesInboxAddress}) has been set to ${aliasedAddress} (aliased from ${crossDomainMsgSenderAddress})`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
