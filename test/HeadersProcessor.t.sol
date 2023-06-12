// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Test} from "forge-std/Test.sol";
import {EOA} from "./helpers/EOA.sol";

import {ICommitmentsInbox} from "../src/interfaces/ICommitmentsInbox.sol";
import {IValidityProofVerifier} from "../src/interfaces/IValidityProofVerifier.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";
import {EVMHeaderRLP} from "../src/lib/EVMHeaderRLP.sol";

uint256 constant DEFAULT_TREE_ID = 0;

contract HeadersProcessor_Processing_Test is Test {
    using EVMHeaderRLP for bytes;
    using Strings for uint256;

    EOA private commitmentsInbox;
    HeadersProcessor private headersProcessor;

    uint256 initialParentHashSentForBlock = 7583803;

    // Emitted event after each successful `append` operation
    event AccumulatorUpdate(bytes32 keccakHash, uint256 processedBlockNumber, uint256 updateId);

    constructor() {
        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_prop.js";
        inputs[2] = initialParentHashSentForBlock.toString();
        inputs[3] = "parentHash";

        bytes memory parentHashBytes = vm.ffi(inputs);
        bytes32 parentHash = bytes32(parentHashBytes);

        commitmentsInbox = new EOA();
        headersProcessor = new HeadersProcessor(ICommitmentsInbox(address(commitmentsInbox)), IValidityProofVerifier(address(0)));
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
        emit AccumulatorUpdate(keccak256(headerRlp), blockNumber, 0);
        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, blockNumber, headerRlp, new bytes32[](0));
        assertEq(headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID), 1);
        assertEq(headersProcessor.mmrsLatestUpdateId(DEFAULT_TREE_ID), 1);
    }

    function test_processBlockFromMessage() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = blockNumber.toString();
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);

        assertEq(headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID), 0);

        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_1), blockNumber, 0);
        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, blockNumber, headerRlp_1, new bytes32[](0));
        assertEq(headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID), 1);

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
        emit AccumulatorUpdate(keccak256(headerRlp_2), nextBlock, 1);
        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, nextBlock, headerRlp_2, nextPeaks);
        assertEq(headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID), 3);
        assertEq(headersProcessor.mmrsLatestUpdateId(DEFAULT_TREE_ID), 2);
    }

    function test_processTillBlock_setup() public returns (bytes memory) {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = blockNumber.toString();
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);

        vm.expectEmit(true, true, true, true);
        emit AccumulatorUpdate(keccak256(headerRlp_1), blockNumber, 0);
        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, blockNumber, headerRlp_1, new bytes32[](0));
        assertEq(headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID), 1);
        assertEq(headersProcessor.mmrsLatestUpdateId(DEFAULT_TREE_ID), 1);
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

        uint256 leafIndex = 1;
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
        emit AccumulatorUpdate(keccak256(headerRlp_2), nextBlock, 1);
        emit AccumulatorUpdate(keccak256(headerRlp_3), nextBlock2, 2);
        emit AccumulatorUpdate(keccak256(headerRlp_4), nextBlock3, 3);
        headersProcessor.processTillBlock(DEFAULT_TREE_ID, leafIndex, leafValue, proof, nextPeaks, headerRlp_1, headersToAppend);
        assertEq(headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID), 7);
        assertEq(headersProcessor.mmrsLatestUpdateId(DEFAULT_TREE_ID), 4);
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

        uint256 leafIndex = 1;
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

        vm.expectRevert("ERR_INVALID_CHAIN_ELEMENT");
        headersProcessor.processTillBlock(DEFAULT_TREE_ID, leafIndex, leafValue, proof, nextPeaks, headerRlp_1, headersToAppend2);
        assertEq(headersProcessor.mmrsLatestUpdateId(DEFAULT_TREE_ID), 1);
    }
}

contract HeadersProcessor_ReceivingParentHashes_Test is Test {
    EOA private commitmentsInbox;
    HeadersProcessor private headersProcessor;

    constructor() {
        commitmentsInbox = new EOA();
        headersProcessor = new HeadersProcessor(ICommitmentsInbox(address(commitmentsInbox)), IValidityProofVerifier(address(0)));
    }

    function test_receiveParentHash() public {
        uint256 blockNumber = 1000;
        bytes32 parentHash = "parent";
        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        assertEq(headersProcessor.receivedParentHashes(blockNumber), parentHash);
        assertEq(headersProcessor.mmrsLatestUpdateId(DEFAULT_TREE_ID), 0);
    }

    function test_fail_receiveParentHash_notCommitmentsInbox() public {
        uint256 blockNumber = 1000;
        bytes32 parentHash = "parent";
        vm.expectRevert("ERR_ONLY_INBOX");
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        assertEq(headersProcessor.mmrsLatestUpdateId(DEFAULT_TREE_ID), 0);
    }
}
