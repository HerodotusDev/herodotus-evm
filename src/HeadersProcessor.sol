// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {ICommitmentsInbox} from "./interfaces/ICommitmentsInbox.sol";

import {EVMHeaderRLP} from "./lib/EVMHeaderRLP.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

contract HeadersProcessor is IHeadersProcessor {
    using EVMHeaderRLP for bytes;

    ICommitmentsInbox public immutable commitmentsInbox;

    uint256 public latestReceived;

    mapping(uint256 => bytes32) public receivedParentHashes;

    // Merkle Mountain Range: on-chain accumulator

    mapping(uint256 => bytes32) public latestRoots;

    mapping(uint256 => uint256) public mmrsElementsCount;

    // @dev: Map MMR ID to a mapping of tree size to root hash
    mapping(uint256 => mapping(uint256 => bytes32)) public mmrsTreeSizeToRoot;

    mapping(uint256 => uint256) public mmrsLatestUpdateId;

    // Emitted event after each successful `append` operation
    event AccumulatorUpdate(uint256 treeId, bytes32 keccakHash, uint256 processedBlockNumber, uint256 updateId);

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

    function processBlockFromMessage(uint256 treeId, uint256 blockNumber, bytes calldata headerSerialized, bytes32[] calldata mmrPeaks) external {
        bytes32 expectedHash = receivedParentHashes[blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bool isValid = isHeaderValid(expectedHash, headerSerialized);
        require(isValid, "ERR_INVALID_HEADER");

        // Append new header to MMR
        mmrAppend(headerSerialized, mmrPeaks, treeId);
    }

    function processTillBlock(
        uint256 treeId,
        uint256 referenceProofLeafIndex,
        bytes32 referenceProofLeafValue,
        bytes32[] calldata referenceProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata referenceHeaderSerialized,
        bytes[] calldata headersSerialized
    ) external {
        // Validate reference block inclusion proof
        validateParentBlockAndProofIntegrity(treeId, referenceProofLeafIndex, referenceProofLeafValue, referenceProof, mmrPeaks, referenceHeaderSerialized);

        // Check serialized headers are cryptographically linked via `parentHash`
        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            require(isHeaderValid(headersSerialized[i - 1].getParentHash(), headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
        }

        // Append new headers to MMR
        mmrMultiAppend(headersSerialized, mmrPeaks, treeId);
    }

    function mmrMultiAppend(bytes[] calldata elements, bytes32[] calldata lastPeaks, uint256 treeId) internal {
        // Getting current mmr state for the treeId
        uint256 nextElementsCount = mmrsElementsCount[treeId];
        bytes32 nextRoot = latestRoots[treeId];
        uint256 lastUpdateId = mmrsLatestUpdateId[treeId];

        // Appending to mmr
        bytes32[] memory nextPeaks = lastPeaks;

        uint updateIdCounter = 0;
        for (uint256 i = 0; i < elements.length; ++i) {
            uint256 processedBlockNumber = elements[i].getBlockNumber();
            bytes32 keccakHash = keccak256(elements[i]);
            (nextElementsCount, nextRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(keccakHash, nextPeaks, nextElementsCount, nextRoot);

            emit AccumulatorUpdate(treeId, keccakHash, processedBlockNumber, lastUpdateId + updateIdCounter);
            ++updateIdCounter;
        }

        // Updating contract storage
        latestRoots[treeId] = nextRoot;
        mmrsTreeSizeToRoot[treeId][nextElementsCount] = nextRoot;
        mmrsElementsCount[treeId] = nextElementsCount;
        mmrsLatestUpdateId[treeId] += updateIdCounter;
    }

    function mmrAppend(bytes calldata element, bytes32[] calldata lastPeaks, uint256 treeId) internal {
        // Getting current mmr state for the treeId
        uint256 lastElementsCount = mmrsElementsCount[treeId];
        bytes32 lastRoot = latestRoots[treeId];
        uint256 lastUpdateId = mmrsLatestUpdateId[treeId];

        // Appending to mmr
        uint256 processedBlockNumber = element.getBlockNumber();
        bytes32 keccakHash = keccak256(element);

        (uint256 nextElementsCount, bytes32 nextRoot) = StatelessMmr.append(keccakHash, lastPeaks, lastElementsCount, lastRoot);

        emit AccumulatorUpdate(treeId, keccakHash, processedBlockNumber, lastUpdateId++);

        // Updating contract storage
        latestRoots[treeId] = nextRoot;
        mmrsTreeSizeToRoot[treeId][nextElementsCount] = nextRoot;
        mmrsElementsCount[treeId] = nextElementsCount;
        mmrsLatestUpdateId[treeId] = lastUpdateId;
    }

    function isHeaderValid(bytes32 hash, bytes calldata header) internal pure returns (bool) {
        return keccak256(header) == hash;
    }

    function validateParentBlockAndProofIntegrity(
        uint256 treeId,
        uint256 referenceProofLeafIndex,
        bytes32 referenceProofLeafValue,
        bytes32[] calldata referenceProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata referenceHeaderSerialized
    ) internal view {
        // Assert the reference block is the one we expect
        require(keccak256(referenceHeaderSerialized) == referenceProofLeafValue, "ERR_INVALID_PROOF_LEAF");

        // Verify the reference block is in the MMR and the proof is valid
        StatelessMmr.verifyProof(referenceProofLeafIndex, referenceProofLeafValue, referenceProof, mmrPeaks, mmrsElementsCount[treeId], latestRoots[treeId]);
    }
}
