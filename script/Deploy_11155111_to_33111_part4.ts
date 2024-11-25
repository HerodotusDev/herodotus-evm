import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const PRIVATE_KEY = process.env.ARBITRUM_PRIVATE_KEY || "";
const apeChainMessageForwarderAddress =
  process.env.DEPLOYED_L2_MSG_FORWARDER || "";
const crossDomainMsgSenderAddress = process.env.DEPLOYED_L1_OUTBOX || "";

if (!PRIVATE_KEY) {
  throw new Error("ARBITRUM_PRIVATE_KEY is not set in .env");
}
if (!apeChainMessageForwarderAddress) {
  throw new Error("DEPLOYED_L2_MSG_FORWARDER is not set in .env");
}
if (!crossDomainMsgSenderAddress) {
  throw new Error("DEPLOYED_L1_OUTBOX is not set in .env");
}

export async function main() {
  // Call setCrossDomainMsgSender on ApeChainMessageForwarder
  const apeChainMessageForwarder = await hre.ethers.getContractAt(
    "ApeChainMessageForwarder",
    apeChainMessageForwarderAddress,
  );

  const aliasedAddress =
    "0x" +
    (
      (BigInt(crossDomainMsgSenderAddress) +
        BigInt("0x1111000000000000000000000000000000001111")) %
      BigInt("0x10000000000000000000000000000000000000000")
    )
      .toString(16)
      .padStart(40, "0");

  const tx =
    await apeChainMessageForwarder.setCrossDomainMsgSender(aliasedAddress);
  await tx.wait();

  console.log(
    "===============================================================",
  );
  console.log(
    `crossDomainMsgSender of ApeChainMessageForwarder(${apeChainMessageForwarderAddress}) has been set to ${aliasedAddress} (aliased from ${crossDomainMsgSenderAddress})`,
  );
  console.log(
    "===============================================================",
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
