require("dotenv").config();
const axios = require("axios");
const RLP = require("rlp");

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
  const accountArgStr = process.argv[3];
  const slotArgStr = process.argv[4];
  const proofType = process.argv[5];

  if (!blockArgStr) throw new Error("Block number has not been provided");
  if (!accountArgStr) throw new Error("Account has not been provided");
  if (!slotArgStr) throw new Error("Storage slot has not been provided");
  if (!proofType) throw new Error("Proof type has not been specified");

  if (!["account", "slot"].includes(proofType))
    throw new Error("Argument proof type is invalid");

  const blockNumber = Number(blockArgStr);

  let proof;
  if (!OFFLINE) {
    const rpcBody = {
      jsonrpc: "2.0",
      method: "eth_getProof",
      params: [accountArgStr, [slotArgStr], "0x" + blockNumber.toString(16)],
      id: 0,
    };
    const rpcResponse = await axios.post(ALCHEMY_URL, JSON.stringify(rpcBody));
    proof = rpcResponse.data.result;
  } else {
    const cached = require("../cached_state_proofs.json");
    proof = cached["GOERLI"][blockArgStr][accountArgStr][slotArgStr];
    if (!proof)
      throw new Error(
        `Proof slot: ${slotArgStr} of ${accountArgStr} at block ${blockArgStr} is not cached`
      );
  }

  if (proofType === "account") {
    console.log(encodeProof(proof.accountProof));
    return;
  }

  if (proofType === "slot") {
    console.log(encodeProof(proof.storageProof[0].proof));
    return;
  }
}

main();
