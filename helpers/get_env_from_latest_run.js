const fs = require("fs");

const chains = [
  [5, "GOERLI"],
  [80001, "MUMBAI"],
];
const contractNamesAndEnvs = [
  ["CommitmentsInbox", "COMMITMENTS_INBOX"],
  ["FactsRegistry", "FACTS_REGISTRY"],
  ["HeadersProcessor", "HEADERS_PROCESSOR"],
];

function main() {
  console.log();
  for (chain of chains) {
    const path = `./broadcast/Deployment.s.sol/${chain[0]}/run-latest.json`;
    if (!fs.existsSync(path)) return console.error("Error: file does not exist: " + path + "\nMake sure to run 'yarn deploy' first\n");

    const latestRun = JSON.parse(fs.readFileSync(path));
    const prefix = chain[1] + "_";
    const envs = contractNamesAndEnvs.reduce(
      (acc, curr) => [...acc, prefix + curr[1] + "=" + latestRun.transactions.find((tx) => tx.contractName === curr[0]).contractAddress],
      []
    );
    console.log(envs.join("\n") + "\n");
  }
}

main();
