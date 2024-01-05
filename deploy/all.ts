import * as hre from "hardhat";
import { deployContract, getWallet } from "./utils";
import { ethers } from "ethers";

const CHAIN_ID = process.env.ZKSYNC_DEPLOY_CHAIN_ID || 300; // Default to zkSync Sepolia testnet

export default async function () {
  const messagesInbox = await deployContract("MessagesInbox");
  const headersProcessor = await deployContract("HeadersProcessor", [messagesInbox.address]);
  const factsRegistry = await deployContract("FactsRegistry", [headersProcessor.address]);

  await initContracts(messagesInbox.address, headersProcessor.address);

  if (process.env.CROSS_MSG_SENDER_ADDRESS) {
    await initCrossMsgSenderOnL2(messagesInbox.address, process.env.CROSS_MSG_SENDER_ADDRESS);
  }

  console.debug('🎉 Done')
}

export async function initCrossMsgSenderOnL2(messagesInboxAddress: string, crossMsgSenderAddress: string) {
  const messagesInboxArtifact = await hre.artifacts.readArtifact("MessagesInbox");
  const messagesInbox = new ethers.Contract(
    messagesInboxAddress,
    messagesInboxArtifact.abi,
    getWallet()
  );

    const tx = await messagesInbox.setCrossDomainMsgSender(crossMsgSenderAddress);
    console.debug(`Setting cross domain message sender to ${crossMsgSenderAddress}... | Tx hash ->`, tx.hash);
    await tx.wait();
}

export async function initContracts(
  messagesInboxAddress: string,
  headersProcessorAddress: string
) {
  const messagesInboxArtifact = await hre.artifacts.readArtifact("MessagesInbox");
  const messagesInbox = new ethers.Contract(
    messagesInboxAddress,
    messagesInboxArtifact.abi,
    getWallet()
  );

  const setHPtx = await messagesInbox.setHeadersProcessor(headersProcessorAddress);
  console.debug(`Setting headers processor to ${headersProcessorAddress}... | Tx hash ->`, setHPtx.hash);
  await setHPtx.wait();

  const setOriginChainIdTx = await messagesInbox.setMessagesOriginChainId(CHAIN_ID);
  await setOriginChainIdTx.wait();
  console.debug(`Setting messages origin chain id to ${CHAIN_ID}... | Tx hash ->`, setOriginChainIdTx.hash);
}
