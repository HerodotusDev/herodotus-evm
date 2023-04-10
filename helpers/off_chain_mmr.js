const { default: CoreMMR } = require("@herodotus_dev/mmr-core");
const { KeccakHasher } = require("@herodotus_dev/mmr-hashes");
const { default: MMRInMemoryStore } = require("@herodotus_dev/mmr-memory");
const { utils, BigNumber } = require("ethers");

function numberStringToBytes32(numberAsString) {
  // Convert the number string to a BigNumber
  const numberAsBigNumber = BigNumber.from(numberAsString);

  // Convert the BigNumber to a zero-padded hex string
  const hexString = utils.hexZeroPad(numberAsBigNumber.toHexString(), 32);

  return hexString;
}

async function main() {
  const store = new MMRInMemoryStore();
  const hasher = new KeccakHasher();
  const encoder = new utils.AbiCoder();
  const mmr = new CoreMMR(store, hasher);

  const numberOfAppend = process.argv[2];
  if (!numberOfAppend) throw new Error("Number of append to perform has not been provided");
  const iterations = Number(numberOfAppend);

  const shouldGenerateProofs = process.argv[3] === "true";

  const results = [];
  for (let idx = 0; idx < iterations; ++idx) {
    const result = await mmr.append((idx + 1).toString());

    if (shouldGenerateProofs) {
      const peaks = await mmr.getPeaks();
      const proof = await mmr.getProof(result.leafIndex);
      results.push({
        index: result.leafIndex.toString(),
        value: numberStringToBytes32((idx + 1).toString()),
        proof: proof.siblingsHashes,
        peaks,
        pos: result.elementsCount.toString(),
        rootHash: result.rootHash,
      });
    } else {
      results.push(result.rootHash);
    }
  }

  if (shouldGenerateProofs) {
    // (uint index, bytes32 value, bytes32[] memory proof, bytes32[] memory peaks, uint pos, bytes32 root)
    const types = ["uint256", "bytes32", "bytes32[]", "bytes32[]", "uint256", "bytes32"];
    const outputs = [];
    for (const result of results) {
      const { index, value, proof, peaks, pos, rootHash } = result;
      const formatted = [index, value, proof, peaks, pos, rootHash];
      // Print each proof and useful values to the standard output
      outputs.push(encoder.encode(types, formatted));
    }
    process.stdout.write(outputs.join(";"));
  } else {
    // Print the root hashes to the standard output
    console.log(encoder.encode(["bytes32[]"], [results]));
  }
}

main();
