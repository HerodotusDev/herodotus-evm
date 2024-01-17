// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";
import {IOutbox} from "./interfaces/IOutbox.sol";

/// @title ArbitrumParentHashesFetcher
/// @notice Fetches parent hashes for the an Arbitrum chain, settling to the chain where this contract is deployed
/// @notice for example if deployed on Ethereum, it will fetch parent hashes for Arbitrum
contract ArbitrumParentHashesFetcher is IParentHashFetcher {
    IOutbox public immutable outbox;

    constructor(IOutbox _outbox) {
        outbox = _outbox;
    }

    function fetchParentHash(bytes memory ctx) external view returns (uint256 fetchedForBlock, bytes32 parentHash) {
        // (bytes32 outputRoot, address l2Sender,
        // address to,
        // uint256 l2Block,
        // uint256 l1Block,
        // uint256 l2Timestamp,
        // uint256 value,
        // uint256 path) = abi.decode(ctx, (bytes32, address, address, uint256, uint256, uint256, uint256, uint256));
        // parentHash = outbox.roots(outputRoot);
        // bytes32 item =  outbox.calculateItemHash(l2Sender, to, l2Block, l1Block, l2Timestamp, value, data);
        // bytes32 merkleRoot = outbox.calculateMerkleRoot(proof, path, item);
        // require(merkleRoot == outputRoot, "ERR_INVALID_OUTPUT_PROPOSAL");
    
        // fetchedForBlock =l2Block;
        // parentHash = parentHash;
        (bytes32 outputRoot, uint256 l2Block) = abi.decode(ctx, (bytes32,uint256));
        parentHash = outbox.roots(outputRoot);
        fetchedForBlock = l2Block;
    }

    function chainId() external view override returns (uint256) {
         return block.chainid;
    }
}