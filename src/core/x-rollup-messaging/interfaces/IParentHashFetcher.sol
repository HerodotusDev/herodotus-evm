// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IParentHashFetcher {
    function fetchParentHash(bytes memory ctx) external view returns (uint256 fetchedForBlock, bytes32 parentHash);

    function chainId() external view returns (uint256);
}