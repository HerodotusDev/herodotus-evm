const { default: CoreMMR } = require("@accumulators/merkle-mountain-range");
const { KeccakHasher } = require("@accumulators/hashers");
const { default: MMRInMemoryStore } = require("@accumulators/memory");
const { utils } = require("ethers");

async function main() {
  const store = new MMRInMemoryStore();
  const hasher = new KeccakHasher();
  const encoder = new utils.AbiCoder();
  const mmr = new CoreMMR(store, hasher);

  const leafIdToProve = process.argv[2];
  const mmrLeaves = process.argv.slice(3);

  const areProvidedValuesIntegers = mmrLeaves.every((leaf) =>
    Number.isInteger(parseInt(leaf))
  );
  const abiEncodingType = areProvidedValuesIntegers ? "uint256[]" : "bytes32[]";

  for (const leaf of mmrLeaves) {
    const appendResult = await mmr.append(leaf);
    // console.log(appendResult, leaf);
  }

  const proof = await mmr.getProof(parseInt(leafIdToProve));
  const root = await mmr.rootHash.get();
  // console.log("proof: ", proof);

  const abiEncodedResult = encoder.encode(
    ["bytes32", abiEncodingType, abiEncodingType],
    [root, proof.peaksHashes, proof.siblingsHashes]
  );
  console.log(abiEncodedResult);
}

main();
