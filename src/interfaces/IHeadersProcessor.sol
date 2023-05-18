// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHeadersProcessor {
    function latestReceived() external view returns (uint256);

    function mmrTreeSizeToRoot(uint256 treeSize) external view returns (bytes32);

    function receivedParentHashes(uint256 blockNumber) external view returns (bytes32);

    function mmrRoot() external view returns (bytes32);

    function mmrElementsCount() external view returns (uint256);

    function mmrLatestUpdateId() external view returns (uint256);

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external;
}
