require("dotenv").config();
const axios = require("axios");
const RLP = require("rlp");

async function main() {
  const { ALCHEMY_URL } = process.env;
  if (!ALCHEMY_URL) throw new Error(`ALCHEMY_URL has not been provided`);

  const arg = process.argv[2];
  if (!arg) throw new Error("Block number has not been provided");
  const blockNumber = Number(arg);

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
    const cached = require("./cached.json");
    header = cached["GOERLI"][blockNumberArg];
    if (!header) throw new Error(`Block ${blockNumberArg} is not cached`);
  }

  const data = [
    header.parentHash,
    header.sha3Uncles,
    header.miner,
    header.stateRoot,
    header.transactionsRoot,
    header.receiptsRoot,
    header.logsBloom,
    header.difficulty,
    header.number,
    header.gasLimit,
    header.gasUsed,
    header.timestamp,
    header.extraData,
    header.mixHash,
    header.nonce,
  ];

  if (header.baseFeePerGas) {
    data.push(header.baseFeePerGas);
  }

  const headerRlp = "0x" + RLP.encode(data).toString("hex");
  console.log(headerRlp);
}

main();
