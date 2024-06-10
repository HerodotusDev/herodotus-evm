// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractStarknetMessagesSender} from "./AbstractStarknetMessagesSender.sol";

import {IStarknetCore} from "../interfaces/IStarknetCore.sol";
import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";
import {ISharpProofsAggregator} from "../../interfaces/ISharpProofsAggregator.sol";

contract L1ToStarknetMessagesSender is AbstractStarknetMessagesSender {
    constructor(
        IStarknetCore starknetCore_,
        uint256 l2RecipientAddr_,
        address aggregatorsFactoryAddr_,
        IParentHashFetcher _parentHashFetcher
    ) AbstractStarknetMessagesSender(starknetCore_, l2RecipientAddr_, aggregatorsFactoryAddr_, _parentHashFetcher) {}

    /// @param aggregatorId The id of a tree previously created by the aggregators factory
    function sendPoseidonMMRTreeToL2(uint256 aggregatorId, uint256 mmrId) external payable override {
        address existingAggregatorAddr = aggregatorsFactory.aggregatorsById(aggregatorId);

        require(existingAggregatorAddr != address(0), "Unknown aggregator");

        ISharpProofsAggregator aggregator = ISharpProofsAggregator(existingAggregatorAddr);
        bytes32 poseidonMMRRoot = aggregator.getMMRPoseidonRoot();
        uint256 mmrSize = aggregator.getMMRSize();

        require(mmrSize >= 1, "Invalid tree size");
        require(poseidonMMRRoot != bytes32(0), "Invalid root (Poseidon)");

        _sendPoseidonMMRTreeToL2(poseidonMMRRoot, mmrSize, aggregatorId, mmrId);
    }
}
