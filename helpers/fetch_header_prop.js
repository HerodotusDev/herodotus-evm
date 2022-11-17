require("dotenv").config();
const axios = require("axios");

async function main() {
  const { ALCHEMY_URL, OFFLINE } = process.env;
  if (!ALCHEMY_URL) throw new Error(`ALCHEMY_URL has not been provided`);

  const blockNumberArg = process.argv[2];
  if (!blockNumberArg) throw new Error("Block number has not been provided");
  const blockNumber = Number(blockNumberArg);

  const propArg = process.argv[3];
  const prop = propArg;

  let header;
  if (!OFFLINE) {
    const rpcBody = {
      jsonrpc: "2.0",
      method: "eth_getBlockByNumber",
      params: ["0x" + blockNumber.toString(16), false],
      id: 0,
    };
    const rpcResponse = await axios.post(ALCHEMY_URL, JSON.stringify(rpcBody));
    header = rpcResponse.data.result;
  } else {
    const cached = require("./cached_headers.json");
    header = cached["GOERLI"][blockNumberArg];
    if(!header) throw new Error(`Block ${blockNumberArg} is not cached`)
  }

  if (!header[prop]) throw new Error("Invalid property name");
  console.log(header[prop]);
}

main();
