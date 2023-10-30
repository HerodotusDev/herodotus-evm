// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {StatelessMmrHelpers} from "solidity-mmr/lib/StatelessMmrHelpers.sol";

import {Test} from "forge-std/Test.sol";
import {EOA} from "./helpers/EOA.sol";

import {HeadersProcessor} from "../src/core/HeadersProcessor.sol";
import {EVMHeaderRLP} from "../src/lib/EVMHeaderRLP.sol";

import "forge-std/console.sol";


contract HeadersProcessor_Test is Test {
    using Strings for uint256;


    uint256 constant DEFAULT_MMR_ID = 0;

    EOA private commitmentsInbox;
    HeadersProcessor private headersProcessor;

    constructor() {
        commitmentsInbox = new EOA();
        headersProcessor = new HeadersProcessor(address(commitmentsInbox));
    }

    function test_receiveParentHash() public {
        bytes32 parentHash = 0x1234567890123456789012345678901234567890123456789012345678901234;

        // Pretend to be the MessagesInbox contract
        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(1, parentHash);

        bytes32 actualParentHash = headersProcessor.receivedParentHashes(1);
        assertEq(actualParentHash, parentHash);
    }

    function test_processBlocksBatchNotAccumulated() public {
        _receiveParentHashOfBlockWithNumber(1000);

        bytes[] memory headersBatch = new bytes[](1);
        headersBatch[0] = _getRlpBlockHeader(999);

        bytes32[] memory emptyPeaks = new bytes32[](0);
        headersProcessor.processBlocksBatch(false, DEFAULT_MMR_ID, abi.encode(999, emptyPeaks), headersBatch);

        uint256 newMMRSize = headersProcessor.getLatestMMRSize(DEFAULT_MMR_ID);
        assertEq(newMMRSize, 1);

        bytes32 mmrRoot = headersProcessor.getMMRRoot(DEFAULT_MMR_ID, newMMRSize);
        assertFalse(mmrRoot == bytes32(0));

        // TODO: Check that the MMR root is correct(expectedRoot)
    }

    function test_processBlocksBatchAccumulated() public {
        // Receive initial parent hash
        _receiveParentHashOfBlockWithNumber(7583803);

        bytes[] memory headersBatch = new bytes[](3);
        headersBatch[0] = _getRlpBlockHeader(7583802);
        headersBatch[1] = _getRlpBlockHeader(7583801);
        headersBatch[2] = _getRlpBlockHeader(7583800);

        // Grow the tree starting from the initial parent hash
        bytes32[] memory emptyPeaks = new bytes32[](0);
        headersProcessor.processBlocksBatch(false, DEFAULT_MMR_ID, abi.encode(7583802, emptyPeaks), headersBatch);

        // Encode the FFI inputs to get the peaks and inclusion proof
        bytes32[] memory hashesInTheMmr = new bytes32[](3);
        hashesInTheMmr[0] = keccak256(headersBatch[0]);
        hashesInTheMmr[1] = keccak256(headersBatch[1]);
        hashesInTheMmr[2] = keccak256(headersBatch[2]);

        uint256 provenLeafId = 1;

        string[] memory inputs = new string[](3 + hashesInTheMmr.length);
        inputs[0] = "node";
        inputs[1] = "./helpers/mmrs/get_peaks_and_inclusion_proof.js";
        inputs[2] = provenLeafId.toString(); // Generate proof for leaf with id
        for (uint256 i = 0; i < hashesInTheMmr.length; i++) {
            inputs[3 + i] = uint256(hashesInTheMmr[i]).toHexString();
        }

        bytes memory abiEncoded = vm.ffi(inputs);
        (bytes32[] memory peaks, bytes32[] memory inclusionProof) = abi.decode(abiEncoded, (bytes32[], bytes32[]));

        // Grow the MMR starting from the blockhash already present in the MMR
        bytes memory ctx = abi.encode(
            provenLeafId,
            inclusionProof,
            peaks,
            headersBatch[0]
        );

        bytes[] memory nextHeadersBatch = new bytes[](1);
        nextHeadersBatch[0] = _getRlpBlockHeader(7583801);
        headersProcessor.processBlocksBatch(true, DEFAULT_MMR_ID, ctx, nextHeadersBatch);

        uint256 newMMRSize = headersProcessor.getLatestMMRSize(DEFAULT_MMR_ID);
        uint256 newLeafCount = StatelessMmrHelpers.mmrSizeToLeafCount(newMMRSize);
        assertEq(newLeafCount, 4);
    }

    function _receiveParentHashOfBlockWithNumber(uint256 blockNumber) internal {
        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_prop.js";
        inputs[2] = blockNumber.toString();
        inputs[3] = "parentHash";

        bytes memory parentHashBytes = vm.ffi(inputs);
        bytes32 parentHash = bytes32(parentHashBytes);

        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(blockNumber, parentHash);
    }

    function _getRlpBlockHeader(uint256 blockNumber) internal returns(bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(inputs);
        return headerRlp;
    }
}
