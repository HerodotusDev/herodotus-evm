// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";
import {IDisputeGameFactory} from "./interfaces/IDisputeGameFactory.sol";
import {DisputeGameStatus} from "../../lib/Types.sol";
import {GameType} from "../../lib/Types.sol";

/// @title OpStackParentHashesFetcher
/// @notice Fetches parent hashes for the an OP stack based chain, settling to the chain where this contract is deployed
/// @notice for example if deployed on Ethereum, it will fetch parent hashes for Optimism/Base
contract OpStackParentHashesFetcher is IParentHashFetcher {
    IDisputeGameFactory public immutable disputeGameFactory;
    uint256 public immutable chainId;
    GameType public immutable respectedGameType;

    constructor(IDisputeGameFactory _disputeGameFactory, uint256 _chainId, GameType _respectedGameType) {
        disputeGameFactory = _disputeGameFactory;
        chainId = _chainId;
        respectedGameType = _respectedGameType;
    }

    function fetchParentHash(bytes memory ctx)
        external
        view
        override
        returns (uint256 fetchedForBlock, bytes32 parentHash)
    {
        (uint256 startSearchGameIndex, bytes memory outputRootPreimage) = abi.decode(ctx, (uint256, bytes));

        // Fetch the latest dispute game
        IDisputeGameFactory.GameSearchResult memory game = disputeGameFactory.findLatestGames(
            respectedGameType,
            startSearchGameIndex,
            1
        )[0];

        require(game.metadata != bytes32(0), "ERR_GAME_NOT_FOUND");
        require(game.status == DisputeGameStatus.DEFENDER_WINS, "ERR_GAME_NOT_RESOLVED");

        // To see the preimage structure and why it is valid, see:
        // https://github.com/ethereum-optimism/optimism/blob/c24298e798f40003f752d12710aa1cad63ad66d1/packages/contracts-bedrock/src/libraries/Hashing.sol#L114
        // https://github.com/ethereum-optimism/optimism/blob/c24298e798f40003f752d12710aa1cad63ad66d1/packages/contracts-bedrock/src/libraries/Types.sol#L25

        // Ensure that the passed preimage matches the output proposal root
        require(game.rootClaim == keccak256(outputRootPreimage), "ERR_INVALID_OUTPUT_PROPOSAL");


        // Decode the values from the preimage
        (,,, bytes32 latestBlockhash) = abi.decode(outputRootPreimage, (bytes32, bytes32, bytes32, bytes32));
        
        // The block number is encoded in the game metadata
        fetchedForBlock = uint256(uint160(bytes20(game.metadata))) + 1;
        parentHash = latestBlockhash;
    }
}
