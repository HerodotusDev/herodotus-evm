// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;


import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";

import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";


contract HeadersProcessor {
    using EVMHeaderRLP for bytes;

    /// @notice This struct represents a Merkle Mountain Range accumulating provably valid block hash
    /// @dev each MMR is mapped to a unique ID also referred to as mmrId
    struct MMRInfo {
        /// @notice latestSize represents the latest size of the MMR
        uint256 latestSize;

        /// @notice mmrSizeToRoot maps the MMR size to the MMR root, that way we have automatic versioning
        mapping(uint256 => bytes32) mmrSizeToRoot;
    }

    /// @notice emitted when a new MMR is created from a single element
    /// @param newMMRId the ID of the new MMR
    /// @param newMMRRoot the root of the new MMR
    /// @param newMMRSize the size of the new MMR
    /// @param detachedFromMmrId the ID of the MMR from which the new MMR was created
    /// @param detachedFromMmrIdAtSize the size of the MMR from which the new MMR was created
    event BranchCreatedFromElement(uint256 newMMRId, bytes32 newMMRRoot, uint256 newMMRSize, uint256 detachedFromMmrId, uint256 detachedFromMmrIdAtSize);
    
    /// @notice emitted when a new MMR is created from an existing MMR
    /// @param newMMRId the ID of the new MMR
    /// @param detachedFromMmrId the ID of the MMR from which the new MMR was created
    /// @param detachedFromMmrIdAtSize the size of the MMR from which the new MMR was created
    event BranchCreatedClone(uint256 newMMRId, uint256 detachedFromMmrId, uint256 detachedFromMmrIdAtSize);

    /// @notice emitted when a new MMR is created from an L1 message
    /// @param newMMRId the ID of the new MMR
    /// @param mmrSize the size of the new MMR
    /// @param mmrRoot the root of the new MMR
    /// @param aggregatorId the ID of the L1 aggregator that is the origin of the message content
    event BranchCreatedFromL1Message(uint256 newMMRId, uint256 mmrSize, bytes32 mmrRoot, uint256 aggregatorId);

    /// @notice emitted when a new batch of blocks is processed
    /// @param startBlockHigh the block number of the first block in the batch
    /// @param endBlockLow the block number of the last block in the batch
    /// @param newMMRRoot the root of the new MMR
    /// @param newMMRSize the size of the new MMR
    /// @param updatedMMRId the ID of the MMR that was updated
    event ProcessedBatch(uint256 startBlockHigh, uint256 endBlockLow, bytes32 newMMRRoot, uint256 newMMRSize, uint256 updatedMMRId);

    /// @notice address of the MessagesInbox contract allowed to forward messages to this contract
    address public immutable messagesInboxAddr;

    /// @notice mapping of block number to the block parent hash
    mapping(uint256 => bytes32) public receivedParentHashes;

    /// @dev counter for the number of MMRs created
    uint256 public mmrsCount;

    /// @dev mapping of MMR ID to MMR info
    mapping (uint256 => MMRInfo) public mmrs;

    /// @param _messagesInboxAddr address of the MessagesInbox contract allowed to forward messages to this contract
    constructor(address _messagesInboxAddr) {
        messagesInboxAddr = _messagesInboxAddr;
    }

    /// @notice modifier to ensure the caller is the MessagesInbox contract
    modifier onlyMessagesInbox() {
        require(msg.sender == messagesInboxAddr, "ERR_ONLY_INBOX");
        _;
    }

    /// @notice Called when a message is sent from L1 to L2
    /// @notice saves the parent hash of the block number in the contract storage
    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external onlyMessagesInbox {
        receivedParentHashes[blockNumber] = parentHash;
    }

    
    /// @notice Creates a new branch from an L1 message, the sent MMR info comes from an L1 aggregator
    /// @param mmrRoot the root of the MMR
    /// @param mmrSize the size of the MMR
    /// @param aggregatorId the ID of the L1 aggregator that is the origin of the message content
    function createBranchFromMessage(bytes32 mmrRoot, uint256 mmrSize, uint256 aggregatorId) external onlyMessagesInbox {
        // 1. Assign an ID to the new MMR
        uint256 currentMMRsCount = mmrsCount;
        uint256 newMMRId = currentMMRsCount + 1;

        // 2. Create a new MMR
        mmrs[newMMRId].latestSize = mmrSize;
        mmrs[newMMRId].mmrSizeToRoot[mmrSize] = mmrRoot;

        // 3. Update the MMRs count
        mmrsCount++;

        // 4. Emit the event
        emit BranchCreatedFromL1Message(newMMRId, mmrSize, mmrRoot, aggregatorId);
    }

    /// @notice Creates a new branch with only one element taken from an existing MMR
    /// @param fromMmrId the ID of the MMR from which the new MMR will be created
    /// @param mmrSize the size of the MMR from which the new MMR will be created
    /// @param elementIndex the index of the element to take from the existing MMR
    /// @param initialBlockHash the block hash of the first block in the new MMR
    /// @param mmrPeaks the peaks of the new MMR
    /// @param mmrIclusionProof the inclusion proof of the element in the existing MMR
    function createBranchSingleElement(
        uint256 fromMmrId,
        uint256 mmrSize,
        uint256 elementIndex,
        bytes32 initialBlockHash,
        bytes32[] calldata mmrPeaks,
        bytes32[] calldata mmrIclusionProof
    ) external {
        // Verify that the given MMR at the given size has a non zero root
        bytes32 root = mmrs[fromMmrId].mmrSizeToRoot[mmrSize];
        require(root != bytes32(0), "ERR_MMR_DOES_NOT_EXIST");

        // Verify that the given element is in the MMR
        StatelessMmr.verifyProof(elementIndex, initialBlockHash, mmrIclusionProof, mmrPeaks, mmrSize, root);

        // === Create a new MMR === //

        // 1. Assign an ID to the new MMR
        uint256 currentMMRsCount = mmrsCount;
        uint256 newMMRId = currentMMRsCount + 1;

        // 2. Create a new MMR
        bytes32[] memory emptyPeaks = new bytes32[](0);
        (uint256 newMMRSize, bytes32 newMMRRoot) = StatelessMmr.append(initialBlockHash, emptyPeaks, 0, bytes32(0));

        // 3. Update the MMRs mapping
        mmrs[newMMRId].latestSize = newMMRSize;
        mmrs[newMMRId].mmrSizeToRoot[newMMRSize] = newMMRRoot;

        // 4. Update the MMRs count
        mmrsCount++;

        // 5. Emit the event
        emit BranchCreatedFromElement(newMMRId, newMMRRoot, newMMRSize, fromMmrId, mmrSize);
    }

    /// @notice Creates a new branch from an existing MMR, effectively cloning it
    /// @param mmrId the ID of the MMR from which the new MMR will be created
    /// @param mmrSize size at which the MMR will be copied
    function createBranchFromExisting(uint256 mmrId, uint256 mmrSize) external {
        // 1. Load existing MMR data
        bytes32 root = mmrs[mmrId].mmrSizeToRoot[mmrSize];

        // 2. Ensure the given MMR is not empty
        require(root != bytes32(0), "ERR_MMR_DOES_NOT_EXIST");

        // 3. Assign an ID to the new MMR
        uint256 currentMMRsCount = mmrsCount;
        uint256 newMMRId = currentMMRsCount + 1;

        // 4. Copy the existing MMR data to the new MMR
        mmrs[newMMRId].latestSize = mmrSize;
        mmrs[newMMRId].mmrSizeToRoot[mmrSize] = root;

        // 5. Update the MMRs count
        mmrsCount++;

        // 6. Emit the event
        emit BranchCreatedClone(newMMRId, mmrId, mmrSize);
    }


    /// @notice Processes a batch of blocks
    /// @param isReferenceHeaderAccumulated whether the reference header is accumulated or not
    /// @param mmrId the ID of the MMR to update
    /// @param ctx the context of the batch, encoded as bytes.
    ///    If the reference header is accumulated, the context contains the MMR proof and peaks.
    ///    If the reference header is not accumulated, the context contains the block number of the reference header and the MMR peaks.
    /// @param headersSerialized the serialized headers of the batch
    function processBlocksBatch(bool isReferenceHeaderAccumulated, uint256 mmrId, bytes calldata ctx, bytes[] calldata headersSerialized) external {
        uint256 firstBlockInBatch;
        uint256 newMMRSize;
        bytes32 newMMRRoot;

        if (isReferenceHeaderAccumulated) {
            (firstBlockInBatch, newMMRSize, newMMRRoot) = _processBlocksBatchAccumulated(mmrId, ctx, headersSerialized);
        } else {
            (firstBlockInBatch, newMMRSize, newMMRRoot) = _processBlocksBatchNotAccumulated(mmrId, ctx, headersSerialized);
        }
        emit ProcessedBatch(firstBlockInBatch, firstBlockInBatch - headersSerialized.length, newMMRRoot, newMMRSize, mmrId);
    }

    /// ========================= Internal functions ========================= //

    function _processBlocksBatchNotAccumulated(uint256 treeId, bytes memory ctx, bytes[] memory headersSerialized) internal returns (uint256 firstBlockInBatch, uint256 newMMRSize, bytes32 newMMRRoot) {
        (uint256 blockNumber, bytes32[] memory mmrPeaks) = abi.decode(ctx, (uint256, bytes32[]));

        bytes32 expectedHash = receivedParentHashes[blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        for (uint256 i = 0; i < headersSerialized.length; i++) {
            require(_isHeaderValid(expectedHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = expectedHash;
            expectedHash = headersSerialized[i].getParentHash();
        }

        (newMMRSize, newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId);
        firstBlockInBatch = blockNumber;
    }

    function _processBlocksBatchAccumulated(uint256 treeId, bytes memory ctx, bytes[] memory headersSerialized) internal returns (uint256 firstBlockInBatch, uint256 newMMRSize, bytes32 newMMRRoot) {
        (   uint256 referenceProofLeafIndex,
            bytes32[] memory referenceProof,
            bytes32[] memory mmrPeaks,
            bytes memory referenceHeaderSerialized
        ) = abi.decode(ctx, (uint256, bytes32[], bytes32[], bytes));

        _validateParentBlockAndProofIntegrity(treeId, referenceProofLeafIndex, referenceProof, mmrPeaks, referenceHeaderSerialized);

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            bytes32 parentHash = headersSerialized[i - 1].getParentHash();
            require(_isHeaderValid(parentHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = parentHash;
        }
        (newMMRSize, newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId);
        firstBlockInBatch = headersSerialized[0].getBlockNumber(); 
    }

    function _appendMultipleBlockhashesToMMR(bytes32[] memory blockhashes, bytes32[] memory lastPeaks, uint256 mmrId) internal returns(uint256 newSize, bytes32 newRoot) {
        // Getting current mmr state for the treeId
        newSize = mmrs[mmrId].latestSize;
        newRoot = mmrs[mmrId].mmrSizeToRoot[newSize];

        // Allocate temporary memory for the next peaks
        bytes32[] memory nextPeaks = lastPeaks;

        for (uint256 i = 0; i < blockhashes.length; ++i) {
            (newSize, newRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(blockhashes[i], nextPeaks, newSize, newRoot);
        }

        // Update the contract storage
        mmrs[mmrId].mmrSizeToRoot[newSize] = newRoot;
        mmrs[mmrId].latestSize = newSize;
    }

    function _isHeaderValid(bytes32 hash, bytes memory header) internal pure returns (bool) {
        return keccak256(header) == hash;
    }

    function _validateParentBlockAndProofIntegrity(
        uint256 mmrId,
        uint256 referenceProofLeafIndex,
        bytes32[] memory referenceProof,
        bytes32[] memory mmrPeaks,
        bytes memory referenceHeaderSerialized
    ) internal view {
        // Verify the reference block is in the MMR and the proof is valid
        uint256 mmrSize = mmrs[mmrId].latestSize;
        bytes32 root = mmrs[mmrId].mmrSizeToRoot[mmrSize];
        StatelessMmr.verifyProof(referenceProofLeafIndex, keccak256(referenceHeaderSerialized), referenceProof, mmrPeaks, mmrSize, root);
    }

    function getMMRRoot(uint256 mmrId, uint256 mmrSize) external view returns (bytes32) {
        return mmrs[mmrId].mmrSizeToRoot[mmrSize];
    }

    function getLatestMMRRoot(uint256 mmrId) external view returns (bytes32) {
        uint256 latestSize = mmrs[mmrId].latestSize;
        return mmrs[mmrId].mmrSizeToRoot[latestSize];
    }

    function getLatestMMRSize(uint256 mmrId) external view returns (uint256) {
        return mmrs[mmrId].latestSize;
    }
}
