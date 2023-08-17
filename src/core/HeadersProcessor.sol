// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";


type ProcessBlocksBatchCtxCaseNotAccumulated is uint256;

contract HeadersProcessor {
    using EVMHeaderRLP for bytes;

    struct MMRInfo {
        uint256 elementsCount;
        bytes32 root;
        uint256 latestUpdateId;
        mapping(uint256 => bytes32) treeSizeToRoot;
    }

    address public immutable messagesInboxAddr;

    mapping(uint256 => bytes32) public receivedParentHashes;

    // Merkle Mountain Range: on-chain accumulator
    mapping (uint256 => MMRInfo) public mmrs;

    // Emitted event after each successful `append` operation
    event AccumulatorUpdates(bytes32 keccakHash, uint256 processedBlockNumber, uint256 updateId, uint256 treeId, uint256 blocksAmount);

    // !Merkle Mountain Range Accumulator

    constructor(address _messagesInboxAddr) {
        messagesInboxAddr = _messagesInboxAddr;
    }

    modifier onlyMessagesInbox() {
        require(msg.sender == messagesInboxAddr, "ERR_ONLY_INBOX");
        _;
    }

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external onlyMessagesInbox {
        receivedParentHashes[blockNumber] = parentHash;
    }

    function processBlocksBatch(bool isReferenceHeaderAccumulated, uint256 treeId, bytes calldata ctx, bytes[] calldata headersSerialized) external {
        if (isReferenceHeaderAccumulated) {
            _processBlocksBatchAccumulated(treeId, ctx, headersSerialized);
        } else {
            _processBlocksBatchNotAccumulated(treeId, ctx, headersSerialized);
        }
    }

    function _processBlocksBatchNotAccumulated(uint256 treeId, bytes memory ctx, bytes[] memory headersSerialized) internal {
        (uint256 blockNumber, bytes32[] memory mmrPeaks) = abi.decode(ctx, (uint256, bytes32[]));

        bytes32 expectedHash = receivedParentHashes[blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            require(_isHeaderValid(expectedHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            expectedHash = headersSerialized[i].getParentHash();
        }

        _mmrMultiAppend(headersSerialized, mmrPeaks, treeId);
    }

    function _processBlocksBatchAccumulated(uint256 treeId, bytes memory ctx, bytes[] memory headersSerialized) internal {
        (   uint256 referenceProofLeafIndex,
            bytes32 referenceProofLeafValue,
            bytes32[] memory referenceProof,
            bytes32[] memory mmrPeaks,
            bytes memory referenceHeaderSerialized
        ) = abi.decode(ctx, (uint256, bytes32, bytes32[], bytes32[], bytes));

        _validateParentBlockAndProofIntegrity(treeId, referenceProofLeafIndex, referenceProofLeafValue, referenceProof, mmrPeaks, referenceHeaderSerialized);

        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            require(_isHeaderValid(headersSerialized[i - 1].getParentHash(), headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
        }

        _mmrMultiAppend(headersSerialized, mmrPeaks, treeId);
    }

    function _mmrMultiAppend(bytes[] memory appendedHeaders, bytes32[] memory lastPeaks, uint256 treeId) internal {
        // Getting current mmr state for the treeId
        uint256 nextElementsCount = mmrs[treeId].elementsCount;
        bytes32 nextRoot = mmrs[treeId].root;
        uint256 lastUpdateId = mmrs[treeId].latestUpdateId;

        // Appending to mmr
        bytes32[] memory nextPeaks = lastPeaks;

        // Necessary for event emitted below
        uint256 firstElementProcessedBlockNumber;
        bytes32 firstElementKeccakHash;

        for (uint256 i = 0; i < appendedHeaders.length; ++i) {
            uint256 processedBlockNumber = appendedHeaders[i].getBlockNumber();
            bytes32 keccakHash = keccak256(appendedHeaders[i]);
            if (i == 0) {
                firstElementProcessedBlockNumber = processedBlockNumber;
                firstElementKeccakHash = keccakHash;
            }
            (nextElementsCount, nextRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(keccakHash, nextPeaks, nextElementsCount, nextRoot);
        }

        // Updating contract storage
        mmrs[treeId].root = nextRoot;
        mmrs[treeId].treeSizeToRoot[nextElementsCount] = nextRoot;
        mmrs[treeId].elementsCount = nextElementsCount;
        mmrs[treeId].latestUpdateId = lastUpdateId + 1;
        emit AccumulatorUpdates(firstElementKeccakHash, firstElementProcessedBlockNumber, lastUpdateId, treeId, appendedHeaders.length);
    }

    function _isHeaderValid(bytes32 hash, bytes memory header) internal pure returns (bool) {
        return keccak256(header) == hash;
    }

    function _validateParentBlockAndProofIntegrity(
        uint256 treeId,
        uint256 referenceProofLeafIndex,
        bytes32 referenceProofLeafValue,
        bytes32[] memory referenceProof,
        bytes32[] memory mmrPeaks,
        bytes memory referenceHeaderSerialized
    ) internal view {
        // Assert the reference block is the one we expect
        require(keccak256(referenceHeaderSerialized) == referenceProofLeafValue, "ERR_INVALID_PROOF_LEAF");

        // Verify the reference block is in the MMR and the proof is valid
        uint256 elementsCount = mmrs[treeId].elementsCount;
        bytes32 root = mmrs[treeId].root;
        StatelessMmr.verifyProof(referenceProofLeafIndex, referenceProofLeafValue, referenceProof, mmrPeaks, elementsCount, root);
    }
}
