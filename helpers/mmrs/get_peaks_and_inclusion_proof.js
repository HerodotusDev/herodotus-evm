const { default: CoreMMR } = require("@accumulators/merkle-mountain-range");
const { KeccakHasher } = require("@accumulators/hashers");
const { default: MMRInMemoryStore } = require("@accumulators/memory");
const { utils, BigNumber } = require("ethers");

async function main() {
  const store = new MMRInMemoryStore();
  const hasher = new KeccakHasher();
  const encoder = new utils.AbiCoder();
  const mmr = new CoreMMR(store, hasher);

  const leafIdToProve = process.argv[2];
  const mmrLeaves = process.argv.slice(3);

  for (const leaf of mmrLeaves) {
    await mmr.append(leaf);
  }

  const peaks = await mmr.getPeaks();
  const proof = await mmr.getProof(parseInt(leafIdToProve));

  const abiEncodedResult = encoder.encode(
    ["bytes32[]", "bytes32[]"],
    [peaks, proof.siblingsHashes]
  );
  console.log(abiEncodedResult);
}

main();
