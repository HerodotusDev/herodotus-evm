// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {EOA} from "./helpers/EOA.sol";

import {ICommitmentsInbox} from "../src/interfaces/ICommitmentsInbox.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";

contract HeadersProcessor_Processing_Test is Test {
    EOA private commitmentsInbox;
    HeadersProcessor private headersProcessor;

    constructor() {
        commitmentsInbox = new EOA();
        headersProcessor = new HeadersProcessor(ICommitmentsInbox(address(commitmentsInbox)));
                vm.prank(address(commitmentsInbox));

    }

    function test_receiveParentHash() public {
        uint256 blockNumber = 1000;
        bytes32 parentHash = "parent";
        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        assertEq(headersProcessor.receivedParentHashes(blockNumber), parentHash);
    }

    function test_fail_receiveParentHash_notCommitmentsInbox() public {
        uint256 blockNumber = 1000;
        bytes32 parentHash = "parent";
        vm.expectRevert("ERR_ONLY_INBOX");
        headersProcessor.receiveParentHash(blockNumber, parentHash);
    }
}

contract HeadersProcessor_ReceivingParentHashes_Test is Test {
    EOA private commitmentsInbox;
    HeadersProcessor private headersProcessor;

    constructor() {
        commitmentsInbox = new EOA();
        headersProcessor = new HeadersProcessor(ICommitmentsInbox(address(commitmentsInbox)));
    }

    function test_receiveParentHash() public {
        uint256 blockNumber = 1000;
        bytes32 parentHash = "parent";
        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        assertEq(headersProcessor.receivedParentHashes(blockNumber), parentHash);
    }

    function test_fail_receiveParentHash_notCommitmentsInbox() public {
        uint256 blockNumber = 1000;
        bytes32 parentHash = "parent";
        vm.expectRevert("ERR_ONLY_INBOX");
        headersProcessor.receiveParentHash(blockNumber, parentHash);
    }
}


