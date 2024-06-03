// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {StatelessMmrHelpers} from "solidity-mmr/lib/StatelessMmrHelpers.sol";
import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";

import {Test} from "forge-std/Test.sol";
import {EOA} from "./helpers/EOA.sol";

import {HeadersStore} from "src/core/HeadersStore.sol";

contract HeadersStore_Test is Test {
    using Strings for uint256;
    using RLPReader for RLPReader.RLPItem;

    uint128 constant DEFAULT_MMR_ID = 1;

    EOA private commitmentsInbox;
    HeadersStore private headersStore;

    event ProcessedBatch(uint256 startBlockHigh, uint256 endBlockLow, bytes32 newMMRRoot, uint256 newMMRSize, uint128 updatedMMRId);

    constructor() {
        commitmentsInbox = new EOA();
        headersStore = new HeadersStore(address(commitmentsInbox));
    }

    function test_receiveHash() public {
        bytes32 parentHash = 0x1234567890123456789012345678901234567890123456789012345678901234;

        // Pretend to be the MessagesInbox contract
        vm.prank(address(commitmentsInbox));
        headersStore.receiveHash(1, parentHash);

        bytes32 actualParentHash = headersStore.receivedParentHashes(1);
        assertEq(actualParentHash, parentHash);
    }

    function test_processBlocksBatchNotAccumulated() public {
        _receiveParentHashOfBlockWithNumber(7583802);

        bytes32[] memory emptyPeaks = new bytes32[](0);

        // Insert a random header as the first element of the MMR
        bytes32 initialElement = _decodeParentHash(_getRlpBlockHeader(7583803));
        (uint256 initialMmrSize, bytes32 initialMmrRoot, bytes32[] memory peaks) = StatelessMmr.appendWithPeaksRetrieval(initialElement, emptyPeaks, 0, bytes32(0));

        vm.prank(address(commitmentsInbox));
        uint256 someAggregatorId = 424242;
        // Register a new authenticated MMR (id 1)
        headersStore.createBranchFromMessage(initialMmrRoot, initialMmrSize, someAggregatorId, DEFAULT_MMR_ID);

        bytes[] memory headersBatch = new bytes[](1);
        headersBatch[0] = _getRlpBlockHeader(7583801);

        headersStore.processBatch(false, DEFAULT_MMR_ID, abi.encode(7583801, peaks), headersBatch);

        uint256 newMMRSize = headersStore.getLatestMMRSize(DEFAULT_MMR_ID);
        assertEq(newMMRSize, 3);

        bytes32 mmrRoot = headersStore.getMMRRoot(DEFAULT_MMR_ID, newMMRSize);
        assertFalse(mmrRoot == bytes32(0));
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

        // Insert a random header as the first element of the MMR
        bytes32 initialElement = _decodeParentHash(_getRlpBlockHeader(7583803));
        (uint256 initialMmrSize, bytes32 initialMmrRoot, bytes32[] memory initialPeaks) = StatelessMmr.appendWithPeaksRetrieval(initialElement, emptyPeaks, 0, bytes32(0));

        vm.prank(address(commitmentsInbox));
        uint256 someAggregatorId = 424242;
        // Register a new authenticated MMR (id 1)
        headersStore.createBranchFromMessage(initialMmrRoot, initialMmrSize, someAggregatorId, DEFAULT_MMR_ID);

        assertEq(initialMmrSize, 1);

        vm.expectEmit();
        emit ProcessedBatch(7583802, 7583800, 0xd586772978d4f45e951c99bf3c7f3f56fd1f5707213b43924204d9d0769a2bd0, 7, DEFAULT_MMR_ID);
        headersStore.processBatch(false, DEFAULT_MMR_ID, abi.encode(7583802, initialPeaks), headersBatch);

        assertEq(StatelessMmrHelpers.mmrSizeToLeafCount(7), 4);

        // Encode the FFI inputs to get the peaks and inclusion proof
        bytes32[] memory hashesInTheMmr = new bytes32[](4);
        hashesInTheMmr[0] = initialElement;
        hashesInTheMmr[1] = keccak256(headersBatch[0]);
        hashesInTheMmr[2] = keccak256(headersBatch[1]);
        hashesInTheMmr[3] = keccak256(headersBatch[2]);

        uint256 provenLeafId = 5;

        string[] memory inputs = new string[](3 + hashesInTheMmr.length);
        inputs[0] = "node";
        inputs[1] = "./helpers/mmrs/get_peaks_and_inclusion_proof.js";
        inputs[2] = provenLeafId.toString(); // Generate proof for leaf with id
        for (uint256 i = 0; i < hashesInTheMmr.length; i++) {
            inputs[3 + i] = uint256(hashesInTheMmr[i]).toHexString();
        }

        bytes memory abiEncoded = vm.ffi(inputs);
        (, bytes32[] memory peaks, bytes32[] memory inclusionProof) = abi.decode(abiEncoded, (bytes32, bytes32[], bytes32[]));

        // Grow the MMR starting from the blockhash already present in the MMR
        bytes memory ctx = abi.encode(provenLeafId, inclusionProof, peaks, headersBatch[2]);

        bytes[] memory nextHeadersBatch = new bytes[](1);
        nextHeadersBatch[0] = _getRlpBlockHeader(7583799);

        vm.expectEmit();
        emit ProcessedBatch(7583799, 7583799, 0x7d911eafd716098fd6d579059f0c670abed0bbb825c350fbbad907ab59c10a45, 8, DEFAULT_MMR_ID);
        headersStore.processBatch(true, DEFAULT_MMR_ID, ctx, nextHeadersBatch);

        uint256 newMMRSize = headersStore.getLatestMMRSize(DEFAULT_MMR_ID);
        uint256 newLeafCount = StatelessMmrHelpers.mmrSizeToLeafCount(newMMRSize);
        assertEq(newLeafCount, 5);

        bytes32 mmrRoot = headersStore.getMMRRoot(DEFAULT_MMR_ID, newMMRSize);
        assertFalse(mmrRoot == bytes32(0));
    }

    function _decodeParentHash(bytes memory headerRlp) internal pure returns (bytes32) {
        return RLPReader.toRLPItem(headerRlp).readList()[0].readBytes32();
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
        headersStore.receiveHash(blockNumber, parentHash);
    }

    function _getRlpBlockHeader(uint256 blockNumber) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(inputs);
        return headerRlp;
    }
}
