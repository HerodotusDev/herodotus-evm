require("dotenv").config();
const { providers, Wallet, utils } = require("ethers");

async function main() {
  const { ALCHEMY_URL, PRIVATE_KEY } = process.env;

  const provider = new providers.StaticJsonRpcProvider(ALCHEMY_URL);
  const wallet = new Wallet(PRIVATE_KEY, provider);

  const address = wallet.address;
  const nonce = await provider.getTransactionCount(address);

  const encoder = new utils.AbiCoder();
  console.log(encoder.encode(["address", "uint256"], [address, nonce]));
}

main();
