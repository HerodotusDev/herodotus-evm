import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const opMessagesInboxAddr = process.env.OP_MESSAGES_INBOX || "";
const headersStoreAddr = process.env.HEADERS_STORE || "";
const factsRegistryAddr = process.env.FACTS_REGISTRY || "";

if (!opMessagesInboxAddr) {
  throw new Error("OP_MESSAGES_INBOX is not set");
}
if (!headersStoreAddr) {
  throw new Error("HEADERS_STORE is not set");
}
if (!factsRegistryAddr) {
  throw new Error("FACTS_REGISTRY is not set");
}

export async function main() {
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
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
