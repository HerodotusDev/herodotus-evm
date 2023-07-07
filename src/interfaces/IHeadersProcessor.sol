// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHeadersProcessor {
    function receivedParentHashes(uint256 blockNumber) external view returns (bytes32);

    function latestRoots(uint256 treeId) external view returns (bytes32);

    function mmrsElementsCount(uint256 treeId) external view returns (uint256);

    function mmrsLatestUpdateId(uint256 treeId) external view returns (uint256);

    function mmrsTreeSizeToRoot(uint256 treeId, uint256 treeSize) external view returns (bytes32);

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external;

    function processBlockFromMessage(uint256 treeId, uint256 blockNumber, bytes calldata headerSerialized, bytes32[] calldata mmrPeaks) external;

    function processTillBlock(
        uint256 treeId,
        bytes32[] calldata referenceProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata referenceHeaderSerialized,
        bytes[] calldata headersSerialized
    ) external;
}
