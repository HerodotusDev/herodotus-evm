// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Test} from "forge-std/Test.sol";
import {EOA} from "./helpers/EOA.sol";

import {ICommitmentsInbox} from "../src/interfaces/ICommitmentsInbox.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";

contract HeadersProcessor_Processing_Test is Test {
    using Strings for uint256;

    EOA private commitmentsInbox;
    HeadersProcessor private headersProcessor;

    uint256 initialParentHashSentForBlock = 7583803;

    constructor() {
        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_prop.js";
        inputs[2] = initialParentHashSentForBlock.toString();
        inputs[3] = "parentHash";

        bytes memory parentHashBytes = vm.ffi(inputs);
        bytes32 parentHash = bytes32(parentHashBytes);

        commitmentsInbox = new EOA();
        headersProcessor = new HeadersProcessor(ICommitmentsInbox(address(commitmentsInbox)));
        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(initialParentHashSentForBlock, parentHash);
    }

    function test_processBlockFromVerifiedHash() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;

        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(inputs);

        headersProcessor.processBlockFromVerifiedHash(0, blockNumber, headerRlp);
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
