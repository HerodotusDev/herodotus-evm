// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";
import {IOutbox} from "./interfaces/IOutbox.sol";
import {EVMHeaderRLP} from "../../../lib/EVMHeaderRLP.sol";

/// @title ArbitrumParentHashesFetcher
/// @notice Fetches parent hashes for the an Arbitrum chain, settling to the chain where this contract is deployed
/// @notice for example if deployed on Ethereum, it will fetch parent hashes for Arbitrum
contract ArbitrumParentHashesFetcher is IParentHashFetcher {
    IOutbox public immutable outbox;
    uint256 public immutable chainId;

    constructor(IOutbox _outbox, uint256 _chainId) {
        outbox = _outbox;
        chainId = _chainId;
    }

    function fetchParentHash(bytes memory ctx) external view override returns (uint256 fetchedForBlock, bytes32 parentHash) {
        (bytes32 outputRoot, bytes memory rlpHeader) = abi.decode(ctx, (bytes32, bytes));
        // Get the block hash from the outbox
        bytes32 l2BlockHash = outbox.roots(outputRoot);
        require(l2BlockHash != bytes32(0), "ERR_INVALID_OUTPUT_ROOT");
        // Validate the header against the parent hash
        require(keccak256(rlpHeader) == l2BlockHash, "ERR_INVALID_HEADER");
        // Get the block number from the header
        uint256 l2BlockNumber = EVMHeaderRLP.getBlockNumber(rlpHeader);
        fetchedForBlock = l2BlockNumber + 1;
        parentHash = l2BlockHash;
    }
}