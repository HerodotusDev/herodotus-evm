// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Test} from "forge-std/Test.sol";
import {EOA} from "./helpers/EOA.sol";

import {ICommitmentsInbox} from "../src/interfaces/ICommitmentsInbox.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";
import {EVMHeaderRLP} from "../src/lib/EVMHeaderRLP.sol";

contract HeadersProcessor_Processing_Test is Test {
    using EVMHeaderRLP for bytes;
    using Strings for uint256;

    EOA private commitmentsInbox;
    HeadersProcessor private headersProcessor;

    uint256 initialParentHashSentForBlock = 7583803;

    // Emitted event after each successful `append` operation
    event AccumulatorUpdate(bytes32 keccakHash, uint processedBlockNumber, uint updateId);

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

    function test_processBlockFromMessage_fromVerifiedHash() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;

        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp), blockNumber, 1);
        headersProcessor.processBlockFromMessage(blockNumber, headerRlp, new bytes32[](0));
        assertEq(headersProcessor.mmrElementsCount(), 1);
    }

    function test_processBlockFromMessage() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = blockNumber.toString();
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);

        assertEq(headersProcessor.mmrElementsCount(), 0);

        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_1), blockNumber, 1);
        headersProcessor.processBlockFromMessage(blockNumber, headerRlp_1, new bytes32[](0));
        assertEq(headersProcessor.mmrElementsCount(), 1);

        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp_1)));

        uint256 nextBlock = blockNumber - 1;
        string[] memory rlp_inputs_2 = new string[](3);
        rlp_inputs_2[0] = "node";
        rlp_inputs_2[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_2[2] = nextBlock.toString();
        bytes memory headerRlp_2 = vm.ffi(rlp_inputs_2);

        bytes32 parentHash = headerRlp_1.getParentHash();
        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(initialParentHashSentForBlock - 1, parentHash);

        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_2), nextBlock, 2);
        headersProcessor.processBlockFromMessage(nextBlock, headerRlp_2, nextPeaks);
        assertEq(headersProcessor.mmrElementsCount(), 3);
    }

    function test_processBlock() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = blockNumber.toString();
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);

        assertEq(headersProcessor.mmrElementsCount(), 0);

        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_1), blockNumber, 1);
        headersProcessor.processBlockFromMessage(blockNumber, headerRlp_1, new bytes32[](0));
        assertEq(headersProcessor.mmrElementsCount(), 1);

        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp_1)));

        uint256 nextBlock = blockNumber - 1;
        string[] memory rlp_inputs_2 = new string[](3);
        rlp_inputs_2[0] = "node";
        rlp_inputs_2[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_2[2] = nextBlock.toString();
        bytes memory headerRlp_2 = vm.ffi(rlp_inputs_2);

        uint leafIndex = 1;
        bytes32 leafValue = keccak256(headerRlp_1);
        bytes32[] memory proof = new bytes32[](0);
        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_2), nextBlock, 2);
        headersProcessor.processBlock(leafIndex, leafValue, proof, nextPeaks, headerRlp_1, headerRlp_2);
    }

    function test_processTillBlock_setup() public returns (bytes memory) {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = blockNumber.toString();
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);

        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_1), blockNumber, 1);
        headersProcessor.processBlockFromMessage(blockNumber, headerRlp_1, new bytes32[](0));
        assertEq(headersProcessor.mmrElementsCount(), 1);
        return headerRlp_1;
    }

    function test_processTillBlock() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        bytes memory headerRlp_1 = test_processTillBlock_setup();

        uint256 nextBlock = blockNumber - 1;
        string[] memory rlp_inputs_2 = new string[](3);
        rlp_inputs_2[0] = "node";
        rlp_inputs_2[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_2[2] = nextBlock.toString();
        bytes memory headerRlp_2 = vm.ffi(rlp_inputs_2);

        uint256 nextBlock2 = blockNumber - 2;
        string[] memory rlp_inputs_3 = new string[](3);
        rlp_inputs_3[0] = "node";
        rlp_inputs_3[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_3[2] = nextBlock2.toString();
        bytes memory headerRlp_3 = vm.ffi(rlp_inputs_3);

        uint256 nextBlock3 = blockNumber - 3;
        string[] memory rlp_inputs_4 = new string[](3);
        rlp_inputs_4[0] = "node";
        rlp_inputs_4[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_4[2] = nextBlock3.toString();
        bytes memory headerRlp_4 = vm.ffi(rlp_inputs_4);

        uint leafIndex = 1;
        bytes32 leafValue = keccak256(headerRlp_1);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory headersToAppend = new bytes[](3);
        headersToAppend[0] = headerRlp_2;
        headersToAppend[1] = headerRlp_3;
        headersToAppend[2] = headerRlp_4;

        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp_1)));
        vm.expectEmit(true, true, true, true);
        vm.expectEmit(true, true, true, true);
        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_2), nextBlock, 2);
        emit AccumulatorUpdate(keccak256(headerRlp_3), nextBlock2, 3);
        emit AccumulatorUpdate(keccak256(headerRlp_4), nextBlock3, 4);
        headersProcessor.processTillBlock(leafIndex, leafValue, proof, nextPeaks, headerRlp_1, headersToAppend);
        assertEq(headersProcessor.mmrElementsCount(), 7);
    }

    function test_processBlock_expect_revert() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        bytes memory headerRlp_1 = test_processTillBlock_setup();

        uint256 nextBlock = blockNumber - 1;
        string[] memory rlp_inputs_2 = new string[](3);
        rlp_inputs_2[0] = "node";
        rlp_inputs_2[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_2[2] = nextBlock.toString();
        bytes memory headerRlp_2 = vm.ffi(rlp_inputs_2);

        uint256 nextBlock2 = blockNumber - 2;
        string[] memory rlp_inputs_3 = new string[](3);
        rlp_inputs_3[0] = "node";
        rlp_inputs_3[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_3[2] = nextBlock2.toString();
        bytes memory headerRlp_3 = vm.ffi(rlp_inputs_3);

        uint256 nextBlock3 = blockNumber - 3;
        string[] memory rlp_inputs_4 = new string[](3);
        rlp_inputs_4[0] = "node";
        rlp_inputs_4[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_4[2] = nextBlock3.toString();
        bytes memory headerRlp_4 = vm.ffi(rlp_inputs_4);

        uint leafIndex = 1;
        bytes32 leafValue = keccak256(headerRlp_1);
        bytes32[] memory proof = new bytes32[](0);
        bytes[] memory headersToAppend = new bytes[](3);
        headersToAppend[0] = headerRlp_2;
        headersToAppend[1] = headerRlp_3;
        headersToAppend[2] = headerRlp_4;

        // Test malicious RLP
        string[] memory rlp_inputs_5 = new string[](4);
        rlp_inputs_5[0] = "node";
        rlp_inputs_5[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_5[2] = nextBlock3.toString();
        rlp_inputs_5[3] = "malicious";
        bytes memory headerRlp_4_malicious = vm.ffi(rlp_inputs_5);
        bytes[] memory headersToAppend2 = new bytes[](3);
        headersToAppend2[0] = headerRlp_2;
        headersToAppend2[1] = headerRlp_3;
        headersToAppend2[2] = headerRlp_4_malicious;
        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp_1)));

        vm.expectRevert("ERR_UNEXPECTED_HEADER");
        headersProcessor.processTillBlock(leafIndex, leafValue, proof, nextPeaks, headerRlp_1, headersToAppend2);

        // Test duplicate headers
        bytes[] memory headersToAppend3 = new bytes[](3);
        headersToAppend3[0] = headerRlp_2;
        headersToAppend3[1] = headerRlp_2;
        headersToAppend3[2] = headerRlp_3;
        vm.expectRevert("ERR_HEADER_DUPLICATE");
        headersProcessor.processTillBlock(leafIndex, leafValue, proof, nextPeaks, headerRlp_1, headersToAppend3);
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
