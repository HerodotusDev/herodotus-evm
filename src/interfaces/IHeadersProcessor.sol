// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHeadersProcessor {
    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external;

    function receivedParentHashes(uint256) external view returns (bytes32);

    function parentHashes(uint256) external view returns (bytes32);

    function stateRoots(uint256) external view returns (bytes32);

    function receiptsRoots(uint256) external view returns (bytes32);

    function transactionsRoots(uint256) external view returns (bytes32);

    function unclesHashes(uint256) external view returns (bytes32);
}
