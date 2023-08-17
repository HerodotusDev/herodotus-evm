// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


import {EOA} from "./helpers/EOA.sol";
import {WETHMock} from "./helpers/WETHMock.sol";

import {MessagesInbox} from "../src/core/MessagesInbox.sol";
import {IHeadersProcessor} from "../src/core/interfaces/IHeadersProcessor.sol";
import {HeadersProcessor} from "../src/core/HeadersProcessor.sol";




// contract MessagesInbox_Test is Test {
//     EOA private owner;
//     EOA private crossdomainDelivery;
//     WETHMock private collateral;

//     HeadersProcessor private headersProcessor;
//     MsgSignerMock private msgSigner;

//     CommitmentsInbox private commitmentsInbox;

//     constructor() {
//         owner = new EOA();

//         collateral = new WETHMock();
//         msgSigner = new MsgSignerMock();

//         commitmentsInbox = new CommitmentsInbox(msgSigner, IERC20(address(collateral)), 0, address(owner), address(crossdomainDelivery));
//         headersProcessor = new HeadersProcessor(commitmentsInbox, IValidityProofVerifier(address(0)));
//         commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
//     }

//     function test_fail_receiveCrossdomainMessage_notCrossdomainMsgSender() public {
//         vm.prank(address(1));
//         vm.expectRevert();
//         commitmentsInbox.receiveCrossdomainMessage(bytes32(uint256(1)), 1, address(0));
//     }

//     function test_receiveCrossdomainMessage_messageSets() public {
//         vm.prank(address(crossdomainDelivery));
//         commitmentsInbox.receiveCrossdomainMessage(bytes32(uint256(1)), 1, address(0));
//         assertEq(headersProcessor.receivedParentHashes(1), bytes32(uint256(1)));
//     }

//     function test_receiveCrossdomainMessage_fraudDetection() public {
//         /// Fraudaulent relayer behaviour
//         bytes memory signature = "0x";
//         commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);

//         /// Resolution
//         vm.prank(address(crossdomainDelivery));
//         // vm.expectEmit(false, false, false, true); TODO fix this
//         commitmentsInbox.receiveCrossdomainMessage(bytes32(uint256(2)), 1, address(0));
//         assertEq(headersProcessor.receivedParentHashes(1), bytes32(uint256(2)));
//     }
// }
