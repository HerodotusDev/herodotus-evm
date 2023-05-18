require("dotenv").config();
// const axios = require("axios");
const RLP = require("rlp");

/**
 *
 * @param {string[]} proof
 */
function encodeProof(proof) {
  return "0x" + RLP.encode(proof.map((part) => RLP.decode(part))).toString("hex");
}

async function main() {
  //   const { ALCHEMY_URL } = process.env;
  //   if (!ALCHEMY_URL) throw new Error(`ALCHEMY_URL has not been provided`);

  const blockArgStr = process.argv[2];
  if (!blockArgStr) throw new Error("Block number has not been provided");

  let proof;

  const cached = require("./cached_receipts_proofs.json");
  proof = cached[blockArgStr][0].receiptProof;

  if (!proof) throw new Error("Not cached");

  console.log(encodeProof(proof));
  return;
}

main();
