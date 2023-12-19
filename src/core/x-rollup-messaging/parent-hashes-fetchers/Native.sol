// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";

/// @title NativeParentHashesFetcher
/// @notice Fetches parent hashes for the native chain
/// @notice for example if deployed on Ethereum, it will fetch parent hashes from Ethereum
contract NativeParentHashesFetcher is IParentHashFetcher {
    function fetchParentHash(bytes memory ctx) external view override returns (uint256 fetchedForBlock, bytes32 parentHash) {
        (fetchedForBlock) = abi.decode(ctx, (uint256));
        parentHash = blockhash(fetchedForBlock - 1);
        require(parentHash != bytes32(0), "ERR_PARENT_HASH_NOT_AVAILABLE");
    }

    function chainId() external view override returns (uint256) {
        return block.chainid;
    }
}
