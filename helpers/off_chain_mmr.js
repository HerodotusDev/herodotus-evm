const { default: CoreMMR } = require("@herodotus_dev/mmr-core");
const { KeccakHasher } = require("@herodotus_dev/mmr-hashes");
const { default: MMRInMemoryStore } = require("@herodotus_dev/mmr-memory");
const { utils } = require("ethers");

const store = new MMRInMemoryStore();
const hasher = new KeccakHasher();
const encoder = new utils.AbiCoder();

async function main() {
  const mmr = new CoreMMR(store, hasher);

  const arg = process.argv[2];
  if (!arg) throw new Error("Number of append to perform has not been provided");
  const iterations = Number(arg);

  const results = [];
  for (let idx = 0; idx < iterations; ++idx) {
    results.push({ ...(await mmr.append((idx + 1).toString())) /* peaks: await mmr.getPeaks() */ });
  }

  const rootHashes = results.map((result) => result.rootHash);
  console.log(encoder.encode(["bytes32[]"], [rootHashes]));
}

main();
