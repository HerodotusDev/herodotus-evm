import { Provider } from "zksync-ethers";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv";
import * as SimpleMessagesInboxArtifact from "../artifacts-zk/src/core/x-rollup-messaging/inbox/SimpleMessagesInbox.sol/SimpleMessagesInbox.json";

dotenv.config();

const PRIVATE_KEY = process.env.ZKSYNC_PRIVATE_KEY || "";
const simpleMessagesInboxAddress = process.env.DEPLOYED_L2_INBOX || "";
const crossDomainMsgSenderAddress = process.env.DEPLOYED_L1_OUTBOX || "";

if (!PRIVATE_KEY) {
  throw new Error("ZKSYNC_PRIVATE_KEY is not set in .env");
}
if (!simpleMessagesInboxAddress) {
  throw new Error("DEPLOYED_L2_INBOX is not set in .env");
}
if (!crossDomainMsgSenderAddress) {
  throw new Error("DEPLOYED_L1_OUTBOX is not set in .env");
}

export default async function (hre: HardhatRuntimeEnvironment) {
  const provider = new Provider(
    (hre.userConfig.networks?.zkSyncSepolia as any)?.url,
  );
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);

  const aliasedAddress =
    "0x" +
    (
      (BigInt(crossDomainMsgSenderAddress) +
        BigInt("0x1111000000000000000000000000000000001111")) %
      BigInt("0x10000000000000000000000000000000000000000")
    ).toString(16);

  // Call setCrossDomainMsgSender on SimpleMessagesInbox
  const simpleMessagesInbox = new ethers.Contract(
    simpleMessagesInboxAddress,
    SimpleMessagesInboxArtifact.abi,
    signer,
  );

  const tx = await simpleMessagesInbox.setCrossDomainMsgSender(aliasedAddress);
  await tx.wait();

  console.log(
    `crossDomainMsgSender of SimpleMessagesInbox(${simpleMessagesInboxAddress}) has been set to ${aliasedAddress} (aliased from ${crossDomainMsgSenderAddress})`,
  );
}
