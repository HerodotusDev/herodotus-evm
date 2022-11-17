// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Test} from "forge-std/Test.sol";
import {EOA} from "./helpers/EOA.sol";

import {ICommitmentsInbox} from "../src/interfaces/ICommitmentsInbox.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";

import {console} from "./helpers/console.sol";

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

        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        headersProcessor.processBlockFromVerifiedHash(0, blockNumber, headerRlp);

        string[] memory parentHash_inputs = new string[](4);
        parentHash_inputs[0] = "node";
        parentHash_inputs[1] = "./helpers/fetch_header_prop.js";
        parentHash_inputs[2] = blockNumber.toString();
        parentHash_inputs[3] = "parentHash";
        bytes memory expectedParentHashBytes = vm.ffi(parentHash_inputs);
        bytes32 expectedParentHash = bytes32(expectedParentHashBytes);

        assertEq(headersProcessor.parentHashes(blockNumber), expectedParentHash);
    }

    function test_processBlock() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = blockNumber.toString();
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);
        headersProcessor.processBlockFromVerifiedHash(0, blockNumber, headerRlp_1);

        uint256 nextBlock = blockNumber - 1;
        string[] memory rlp_inputs_2 = new string[](3);
        rlp_inputs_2[0] = "node";
        rlp_inputs_2[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_2[2] = nextBlock.toString();
        bytes memory headerRlp_2 = vm.ffi(rlp_inputs_2);
        headersProcessor.processBlock(0, nextBlock, headerRlp_2);

        string[] memory parentHash_inputs = new string[](4);
        parentHash_inputs[0] = "node";
        parentHash_inputs[1] = "./helpers/fetch_header_prop.js";
        parentHash_inputs[2] = nextBlock.toString();
        parentHash_inputs[3] = "parentHash";
        bytes memory expectedParentHashBytes = vm.ffi(parentHash_inputs);
        bytes32 expectedParentHash = bytes32(expectedParentHashBytes);

        assertEq(headersProcessor.parentHashes(nextBlock), expectedParentHash);
    }

    function test_processBlock_settingUnclesHash() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;

        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        uint16 bitmap = 2; // 0b10
        headersProcessor.processBlockFromVerifiedHash(bitmap, blockNumber, headerRlp);

        string[] memory unclesHash_inputs = new string[](4);
        unclesHash_inputs[0] = "node";
        unclesHash_inputs[1] = "./helpers/fetch_header_prop.js";
        unclesHash_inputs[2] = blockNumber.toString();
        unclesHash_inputs[3] = "sha3Uncles";
        bytes memory expectedUnclesHashBytes = vm.ffi(unclesHash_inputs);
        bytes32 expectedUnclesHash = bytes32(expectedUnclesHashBytes);

        assertEq(headersProcessor.unclesHashes(blockNumber), expectedUnclesHash);
    }

    function test_processBlock_settingStateRoot() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;

        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        uint16 bitmap = 8; // 0b1000
        headersProcessor.processBlockFromVerifiedHash(bitmap, blockNumber, headerRlp);

        string[] memory stateRoot_inputs = new string[](4);
        stateRoot_inputs[0] = "node";
        stateRoot_inputs[1] = "./helpers/fetch_header_prop.js";
        stateRoot_inputs[2] = blockNumber.toString();
        stateRoot_inputs[3] = "stateRoot";
        bytes memory expectedStateRootBytes = vm.ffi(stateRoot_inputs);
        bytes32 expectedStateRoot = bytes32(expectedStateRootBytes);

        assertEq(headersProcessor.stateRoots(blockNumber), expectedStateRoot);
    }

    function test_processBlock_settingTransactionsRoot() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;

        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        uint16 bitmap = 16; // 0b10000
        headersProcessor.processBlockFromVerifiedHash(bitmap, blockNumber, headerRlp);

        string[] memory transactionsRoot_inputs = new string[](4);
        transactionsRoot_inputs[0] = "node";
        transactionsRoot_inputs[1] = "./helpers/fetch_header_prop.js";
        transactionsRoot_inputs[2] = blockNumber.toString();
        transactionsRoot_inputs[3] = "transactionsRoot";
        bytes memory expectedTransactionsRootBytes = vm.ffi(transactionsRoot_inputs);
        bytes32 expectedTransactionsRoot = bytes32(expectedTransactionsRootBytes);

        assertEq(headersProcessor.transactionsRoots(blockNumber), expectedTransactionsRoot);
    }

    function test_processBlock_settingReceiptsRoot() public {
        uint256 blockNumber = initialParentHashSentForBlock - 1;

        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        uint16 bitmap = 32; // 0b100000
        headersProcessor.processBlockFromVerifiedHash(bitmap, blockNumber, headerRlp);

        string[] memory receiptsRoot_inputs = new string[](4);
        receiptsRoot_inputs[0] = "node";
        receiptsRoot_inputs[1] = "./helpers/fetch_header_prop.js";
        receiptsRoot_inputs[2] = blockNumber.toString();
        receiptsRoot_inputs[3] = "receiptsRoot";
        bytes memory expectedReceiptsRootBytes = vm.ffi(receiptsRoot_inputs);
        bytes32 expectedReceiptsRoot = bytes32(expectedReceiptsRootBytes);

        assertEq(headersProcessor.receiptsRoots(blockNumber), expectedReceiptsRoot);
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
