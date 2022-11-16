require("dotenv").config();
const axios = require("axios");
const RLP = require("rlp");

async function main() {
  const { ALCHEMY_URL } = process.env;
  if (!ALCHEMY_URL) throw new Error(`ALCHEMY_URL has not been provided`);

  const blockNumberArg = process.argv[2];
  if (!blockNumberArg) throw new Error("Block number has not been provided");
  const blockNumber = Number(blockNumberArg);

  const propArg = process.argv[3];
  const prop = propArg;

  const rpcBody = {
    jsonrpc: "2.0",
    method: "eth_getBlockByNumber",
    params: ["0x" + blockNumber.toString(16), false],
    id: 0,
  };
  const rpcResponse = await axios.post(ALCHEMY_URL, JSON.stringify(rpcBody));
  const header = rpcResponse.data.result;

  if (!header[prop]) throw new Error("Invalid property name");
  console.log(header[prop]);
}

main();
