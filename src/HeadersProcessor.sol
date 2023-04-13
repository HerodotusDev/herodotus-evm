// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {ICommitmentsInbox} from "./interfaces/ICommitmentsInbox.sol";

import {EVMHeaderRLP} from "./lib/EVMHeaderRLP.sol";
import {Bitmap16} from "./lib/Bitmap16.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

contract HeadersProcessor is IHeadersProcessor {
    using Bitmap16 for uint16;
    using EVMHeaderRLP for bytes;

    ICommitmentsInbox public immutable commitmentsInbox;

    uint256 public latestReceived;

    mapping(uint256 => bytes32) public receivedParentHashes;

    mapping(uint256 => bytes32) public parentHashes;

    // Merkle Mountain Range: on-chain accumulator

    bytes32 public mmrRoot; // Current root hash

    uint256 public mmrElementsCount; // Current elements count

    mapping(uint256 => bytes32) public mmrTreeSizeToRoot; // Mapping of elements count to relative root hash

    uint256 public mmrLatestUpdateId; // Latest update id

    // Emitted event after each successful `append` operation
    event AccumulatorUpdate(bytes32 keccakHash, uint256 processedBlockNumber, uint256 updateId);

    // !Merkle Mountain Range Accumulator

    constructor(ICommitmentsInbox _commitmentsInbox) {
        commitmentsInbox = _commitmentsInbox;
    }

    modifier onlyCommitmentsInbox() {
        require(msg.sender == address(commitmentsInbox), "ERR_ONLY_INBOX");
        _;
    }

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external onlyCommitmentsInbox {
        if (blockNumber > latestReceived) {
            latestReceived = blockNumber;
        }
        receivedParentHashes[blockNumber] = parentHash;
    }

    function processBlockFromMessage(uint256 blockNumber, bytes calldata headerSerialized, bytes32[] calldata mmrPeaks) external {
        bytes32 expectedHash = parentHashes[blockNumber + 1];
        if (expectedHash == bytes32(0)) {
            expectedHash = receivedParentHashes[blockNumber + 1];
        }
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bool isValid = isHeaderValid(expectedHash, headerSerialized);
        require(isValid, "ERR_INVALID_HEADER");

        // Append new header to MMR
        mmrAppend(headerSerialized, mmrPeaks, mmrElementsCount, mmrRoot);
    }

    function processBlock(
        uint256 referenceProofLeafIndex,
        bytes32 referenceProofLeafValue,
        bytes32[] calldata referenceProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata referenceHeaderSerialized,
        bytes calldata headerSerialized
    ) external {
        // Validate reference block inclusion proof
        validateParentBlockAndProofIntegrity(referenceProofLeafIndex, referenceProofLeafValue, referenceProof, mmrPeaks, referenceHeaderSerialized, headerSerialized);

        // Append new header to MMR
        mmrAppend(headerSerialized, mmrPeaks, mmrElementsCount, mmrRoot);
    }

    function processTillBlock(
        uint256 referenceProofLeafIndex,
        bytes32 referenceProofLeafValue,
        bytes32[] calldata referenceProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata referenceHeaderSerialized,
        bytes[] calldata headersSerialized
    ) external {
        // Check block numbers are consecutive and in descending order
        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            uint prevBlockNumber = headersSerialized[i - 1].getBlockNumber();
            uint currBlockNumber = headersSerialized[i].getBlockNumber();

            require(currBlockNumber != prevBlockNumber, "ERR_HEADER_DUPLICATE");
            require(currBlockNumber == prevBlockNumber - 1, "ERR_HEADER_NON_CONSECUTIVE_DESC");
        }

        // Validate reference block inclusion proof
        validateParentBlockAndProofIntegrity(referenceProofLeafIndex, referenceProofLeafValue, referenceProof, mmrPeaks, referenceHeaderSerialized, headersSerialized[0]);

        // Append new headers to MMR
        mmrMultiAppend(headersSerialized, mmrPeaks, mmrElementsCount, mmrRoot);
    }

    function isHeaderValid(bytes32 hash, bytes calldata header) public pure returns (bool) {
        return keccak256(header) == hash;
    }

    function mmrAppend(bytes calldata element, bytes32[] calldata lastPeaks, uint256 lastElementsCount, bytes32 lastRoot) internal {
        uint256 processedBlockNumber = element.getBlockNumber();
        bytes32 keccakHash = keccak256(element);

        (uint256 nextElementsCount, bytes32 nextRoot) = StatelessMmr.append(keccakHash, lastPeaks, lastElementsCount, lastRoot);

        emit AccumulatorUpdate(keccakHash, processedBlockNumber, ++mmrLatestUpdateId);

        // Update contract storage
        mmrTreeSizeToRoot[nextElementsCount] = nextRoot;
        mmrRoot = nextRoot;
        mmrElementsCount = nextElementsCount;
    }

    function mmrMultiAppend(bytes[] calldata elements, bytes32[] calldata lastPeaks, uint256 lastElementsCount, bytes32 lastRoot) internal {
        uint256 nextElementsCount = lastElementsCount;
        bytes32 nextRoot = lastRoot;
        bytes32[] memory nextPeaks = lastPeaks;

        for (uint256 i = 0; i < elements.length; ++i) {
            uint256 processedBlockNumber = elements[i].getBlockNumber();
            bytes32 keccakHash = keccak256(elements[i]);
            (nextElementsCount, nextRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(keccakHash, nextPeaks, nextElementsCount, nextRoot);

            emit AccumulatorUpdate(keccakHash, processedBlockNumber, ++mmrLatestUpdateId);
            // Update contract storage
            mmrTreeSizeToRoot[nextElementsCount] = lastRoot;
        }

        // Update contract storage
        mmrRoot = nextRoot;
        mmrElementsCount = nextElementsCount;
    }

    function validateParentBlockAndProofIntegrity(
        uint256 referenceProofLeafIndex,
        bytes32 referenceProofLeafValue,
        bytes32[] calldata referenceProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata referenceHeaderSerialized,
        bytes calldata headerSerialized
    ) internal view {
        // Assert the reference block is the one we expect
        require(keccak256(referenceHeaderSerialized) == referenceProofLeafValue, "ERR_PROOF_HASH_MISMATCH");

        // Verify the reference block is in the MMR and the proof is valid
        StatelessMmr.verifyProof(referenceProofLeafIndex, referenceProofLeafValue, referenceProof, mmrPeaks, mmrElementsCount, mmrRoot);

        // Reference block's parent hash
        bytes32 childBlockParentHash = referenceHeaderSerialized.getParentHash();

        // Parent's block hash (the candidate block to append)
        bool isValid = isHeaderValid(childBlockParentHash, headerSerialized);
        require(isValid, "ERR_INVALID_HEADER");
    }
}
