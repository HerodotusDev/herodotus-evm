// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {MessagesInbox} from "../src/core/MessagesInbox.sol";
import {HeadersProcessor} from "../src/core/HeadersProcessor.sol";
import {FactsRegistry} from "../src/core/FactsRegistry.sol";

import {IMessagesInbox} from "../src/core/interfaces/IMessagesInbox.sol";

import {CREATE} from "../src/lib/CREATE.sol";

import {WETHMock} from "../test/helpers/WETHMock.sol";

// contract Deployment is Script {
//     function run() public {
//         vm.startBroadcast();

//         string[] memory getNonce_inputs = new string[](2);
//         getNonce_inputs[0] = "node";
//         getNonce_inputs[1] = "./helpers/fetch_account_nonce.js";
//         bytes memory result = vm.ffi(getNonce_inputs);

//         (address deployer, uint256 deployerNonce) = abi.decode(result, (address, uint256));

//         address predictedHeadersProcessor = CREATE.computeFutureAddress(deployer, deployerNonce + 2);
//         address predictedCommitmentsInbox = CREATE.computeFutureAddress(deployer, deployerNonce + 3);

//         HeadersProcessor headersProcessor = new HeadersProcessor(ICommitmentsInbox(predictedCommitmentsInbox), IValidityProofVerifier(address(0)));
//         CommitmentsInbox commitmentsInbox = new CommitmentsInbox(IMsgSigner(predictedSigner), IERC20(predictedWethMock), 0, address(this), address(0));
//         commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
//         new Secp256k1MsgSigner(deployer, deployer);
//         new FactsRegistry(IHeadersProcessor(predictedHeadersProcessor));
//         new WETHMock();

//         vm.stopBroadcast();
//     }
// }
