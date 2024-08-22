import dotenv from "dotenv";
import hre from "hardhat";

dotenv.config();

const simpleMessagesInboxAddr = process.env.SIMPLE_MESSAGES_INBOX || "";
const headersStoreAddr = process.env.HEADERS_STORE || "";
const factsRegistryAddr = process.env.FACTS_REGISTRY || "";

if (!simpleMessagesInboxAddr) {
  throw new Error("SIMPLE_MESSAGES_INBOX is not set");
}
if (!headersStoreAddr) {
  throw new Error("HEADERS_STORE is not set");
}
if (!factsRegistryAddr) {
  throw new Error("FACTS_REGISTRY is not set");
}

export async function main() {
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
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
