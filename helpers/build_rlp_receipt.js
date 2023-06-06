require("dotenv").config();
const rlp = require("rlp");
const { ethers } = require("ethers");

async function getRLPEncodedReceipt() {
  const { ALCHEMY_URL } = process.env;
  if (!ALCHEMY_URL) throw new Error(`ALCHEMY_URL has not been provided`);
  const provider = new ethers.providers.JsonRpcProvider(ALCHEMY_URL);

  const txHashArg = process.argv[2];
  if (!txHashArg) throw new Error("Tx hash arg has not been provided");

  const receipt = await provider.getTransactionReceipt(txHashArg);

  // Convert the logs into an array format that can be RLP encoded
  const logsArray = receipt.logs.map((log) => [log.address, log.topics, log.data]);

  // Construct an array with the receipt fields
  const receiptArray = [receipt.status ? "0x01" : "0x", receipt.cumulativeGasUsed.toHexString(), receipt.logsBloom, logsArray];

  // RLP encode the receipt array
  const encodedReceipt = rlp.encode(receiptArray);

  // RLP encoded receipt:
  console.log(encodedReceipt.toString("hex"));
}

getRLPEncodedReceipt();
