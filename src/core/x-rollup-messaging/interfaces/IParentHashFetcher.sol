// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IParentHashFetcher {
    function fetchParentHash(bytes memory ctx) external view returns (uint256 fetchedForBlock, bytes32 parentHash);

    function chainId() external view returns (uint256);
}
