require("dotenv").config();
const { keccak256 } = require("@ethersproject/keccak256");
const axios = require("axios");
const RLP = require("rlp");

async function main() {
  const { ALCHEMY_URL, OFFLINE } = process.env;
  if (!ALCHEMY_URL) throw new Error(`ALCHEMY_URL has not been provided`);

  const arg = process.argv[2];
  if (!arg) throw new Error("Block number has not been provided");
  const blockNumber = Number(arg);

  let header;
  if (!OFFLINE || OFFLINE === "false") {
    const rpcBody = {
      jsonrpc: "2.0",
      method: "eth_getBlockByNumber",
      params: ["0x" + blockNumber.toString(16), false],
      id: 0,
    };
    const rpcResponse = await axios.post(ALCHEMY_URL, JSON.stringify(rpcBody), { headers: { "Content-Type": "application/json" } });
    header = rpcResponse.data.result;
  } else {
    const cached = require("./cached_headers.json");
    header = cached["GOERLI"][arg];
    if (!header) throw new Error(`Block ${arg} is not cached`);
  }

  const data = [
    header.parentHash,
    header.sha3Uncles,
    header.miner,
    header.stateRoot,
    header.transactionsRoot,
    header.receiptsRoot,
    header.logsBloom,
    header.difficulty === "0x0" ? "0x" : header.difficulty,
    header.number,
    header.gasLimit,
    header.gasUsed === "0x0" ? "0x" : header.gasUsed,
    header.timestamp,
    header.extraData,
    header.mixHash,
    header.nonce,
  ];

  if (header.baseFeePerGas) {
    data.push(header.baseFeePerGas);
  }

  if (header.withdrawalsRoot) {
    data.push(header.withdrawalsRoot);
  }

  const isMalicious = process.argv[3] === "malicious";
  if (isMalicious) {
    data[3] = "0x4f8a2f80c6496e18bd911ba09b6cbb01e78b7637845c69253f2eec2875a67278"; // Fake state root
  }
  const headerRlp = "0x" + RLP.encode(data).toString("hex");
  const actualHash = keccak256(headerRlp);
  if (!isMalicious && actualHash !== header.hash) throw new Error(`Mismatching blockhashes expected: ${header.hash}, actual: ${actualHash}`);
  console.log(headerRlp);
}

main();
