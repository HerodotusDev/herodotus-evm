// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHeadersStorage {
    function parentHashes(uint256) external view returns (bytes32);

    function stateRoots(uint256) external view returns (bytes32);

    function receiptsRoots(uint256) external view returns (bytes32);

    function transactionsRoots(uint256) external view returns (bytes32);

    function unclesHashes(uint256) external view returns (bytes32);
}
