require("dotenv").config();
const axios = require("axios");
const RLP = require("rlp");
const { utils } = require("ethers");

/**
 *
 * @param {string[]} proof
 */
function encodeProof(proof) {
  return (
    "0x" + RLP.encode(proof.map((part) => RLP.decode(part))).toString("hex")
  );
}

async function main() {
  const { ALCHEMY_URL, OFFLINE } = process.env;
  if (!ALCHEMY_URL) throw new Error(`ALCHEMY_URL has not been provided`);

  const blockArgStr = process.argv[2];
  const transactionIndexArgStr = process.argv[3];

  if (!blockArgStr) throw new Error("Block number has not been provided");
  if (!transactionIndexArgStr) throw new Error("Transaction index has not been provided");

  const blockNumber = Number(blockArgStr);

  let proof;
//   if (!OFFLINE || OFFLINE === "false") {
//     const rpcBody = {
//       jsonrpc: "2.0",
//       method: "eth_getProof",
//       params: [accountArgStr, [slotArgStr], "0x" + blockNumber.toString(16)],
//       id: 0,
//     };
//     const rpcResponse = await axios.post(ALCHEMY_URL, JSON.stringify(rpcBody));
//     proof = rpcResponse.data.result;
//   } else {
    const cached = require("../cached_transaction_proofs.json");
    proof = cached["SEPOLIA"][blockArgStr]["TX_PROOFS"][transactionIndexArgStr];
    if (!proof)
      throw new Error(
        `Transaction root at block ${blockArgStr} for transaction index  ${transactionIndexArgStr}  is not cached`
      );
  //}

  const trieProof = proof;

  const encoder = new utils.AbiCoder();

  const trieProofRlp = "0x" + RLP.encode(trieProof).toString("hex");
  const encodedProof = encoder.encode(["bytes"], [trieProofRlp]);
  // const result = encodeProof(trieProof);
  console.log(encodedProof);
}

main();
