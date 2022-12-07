// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {CommitmentsInbox} from "../src/CommitmentsInbox.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";
import {FactsRegistry} from "../src/FactsRegistry.sol";
import {Secp256k1MsgSigner} from "../src/msg-signers/Secp256k1MsgSigner.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHeadersProcessor} from "../src/interfaces/IHeadersProcessor.sol";
import {IHeadersStorage} from "../src/interfaces/IHeadersStorage.sol";

import {ICommitmentsInbox} from "../src/interfaces/ICommitmentsInbox.sol";

import {IMsgSigner} from "../src/interfaces/IMsgSigner.sol";

import {CREATE} from "../src/lib/CREATE.sol";

contract Deployment is Script {
    function run() public {
        vm.startBroadcast();

        string[] memory getNonce_inputs = new string[](2);
        getNonce_inputs[0] = "node";
        getNonce_inputs[1] = "./helpers/fetch_account_nonce.js";
        bytes memory result = vm.ffi(getNonce_inputs);

        (address deployer, uint256 deployerNonce) = abi.decode(result, (address, uint256));

        address predictedHeadersProcessor = CREATE.computeFutureAddress(deployer, deployerNonce + 2);
        address predictedCommitmentsInbox = CREATE.computeFutureAddress(deployer, deployerNonce + 3);
        address predictedSigner = CREATE.computeFutureAddress(deployer, deployerNonce + 4);

        new HeadersProcessor(ICommitmentsInbox(predictedCommitmentsInbox));
        new CommitmentsInbox(IHeadersProcessor(predictedHeadersProcessor), IMsgSigner(predictedSigner), IERC20(address(0)), 0, address(0), address(0));
        new Secp256k1MsgSigner(deployer, deployer);
        new FactsRegistry(IHeadersStorage(predictedHeadersProcessor));

        vm.stopBroadcast();
    }
}