const fs = require("fs");
const { env } = require("custom-env");

const chains = [
  [5, "GOERLI"],
  [80001, "MUMBAI"],
];
const contractNamesAndEnvs = [
  ["CommitmentsInbox", "syncTypes->OPTIMISTIC-> address"],
  ["FactsRegistry", "factsRegistry"],
  ["HeadersProcessor", "headersProcessor"],
];

function main() {
  console.log();
  for (chain of chains) {
    const path = `./broadcast/Deployment.s.sol/${chain[0]}/run-latest.json`;
    if (!fs.existsSync(path)) return console.error("Error: file does not exist: " + path + "\nMake sure to run 'yarn deploy' first\n");

    const latestRun = JSON.parse(fs.readFileSync(path));
    const prefix = chain[1] + "->connections->" + chains.filter((c) => c[0] !== chain[0])[0][1] + "->";
    const envs = contractNamesAndEnvs.reduce(
      (acc, curr) => [...acc, prefix + curr[1] + " = " + latestRun.transactions.find((tx) => tx.contractName === curr[0]).contractAddress],
      []
    );
    env(chain[1].toLowerCase());
    console.log(prefix + "syncTypes->OPTIMISTIC->relayerPrivateKey = " + process.env["PRIVATE_KEY"]);
    process.env = {};
    console.log(envs.join("\n") + "\n");
  }
}

main();
