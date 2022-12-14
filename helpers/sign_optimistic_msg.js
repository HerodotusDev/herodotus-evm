require("dotenv").config();
const { utils } = require("ethers");
const { keccak256, joinSignature } = require("ethers/lib/utils");

async function main() {
  const { PRIVATE_KEY } = process.env;

  const methodSelector = process.argv[2];
  if (!methodSelector) throw new Error("Method selector has not been provided");

  const parentHash = process.argv[3];
  if (!parentHash) throw new Error("Parent hash has not been provided");

  const blockNumber = process.argv[4];
  if (!blockNumber) throw new Error("Block number has not been provided");

  const contractAddress = process.argv[5];
  if (!contractAddress) throw new Error("Contract address has not been provided");

  const msg = utils.defaultAbiCoder.encode(
    ["bytes4", "bytes32", "uint256", "address"],
    [methodSelector, utils.hexZeroPad(parentHash, 32), blockNumber, utils.hexZeroPad(contractAddress, 20)]
  );
  const msgHash = keccak256(msg);

  const signature = new utils.SigningKey(PRIVATE_KEY).signDigest(msgHash);
  console.log(joinSignature(signature));
}

main();
