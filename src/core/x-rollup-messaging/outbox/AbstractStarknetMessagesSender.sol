// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IStarknetCore} from "../interfaces/IStarknetCore.sol";

import {ISharpProofsAggregator} from "../../interfaces/ISharpProofsAggregator.sol";
import {ISharpProofsAggregatorsFactory} from "../../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";

import {Uint256Splitter} from "../../../lib/Uint256Splitter.sol";

abstract contract AbstractStarknetMessagesSender is Ownable {
    using Uint256Splitter for uint256;

    IStarknetCore public immutable starknetCore;
    IParentHashFetcher public immutable parentHashFetcher;

    uint256 public l2RecipientAddr;

    ISharpProofsAggregatorsFactory public aggregatorsFactory;

    /// @dev L2 "receive_commitment" L1 handler selector
    uint256 constant RECEIVE_COMMITMENT_L1_HANDLER_SELECTOR = 0x3fa70707d0e831418fb142ca8fb7483611b84e89c0c42bf1fc2a7a5c40890ad;

    /// @dev L2 "receive_mmr" L1 handler selector
    uint256 constant RECEIVE_MMR_L1_HANDLER_SELECTOR = 0x36c76e67f1d589956059cbd9e734d42182d1f8a57d5876390bb0fcfe1090bb4;

    /// @param starknetCore_ a StarknetCore address to send and consume messages on/from L2
    /// @param l2RecipientAddr_ a L2 recipient address that is the recipient contract on L2.
    /// @param aggregatorsFactoryAddr_ Herodotus aggregators factory address (where MMR trees are referenced)
    constructor(IStarknetCore starknetCore_, uint256 l2RecipientAddr_, address aggregatorsFactoryAddr_, IParentHashFetcher _parentHashFetcher) Ownable(msg.sender) {
        starknetCore = starknetCore_;
        parentHashFetcher = _parentHashFetcher;
        l2RecipientAddr = l2RecipientAddr_;
        aggregatorsFactory = ISharpProofsAggregatorsFactory(aggregatorsFactoryAddr_);
    }

    /// @notice Send an exact L1 parent hash to L2
    /// @param _parentHashFetcherCtx ABI encoded context for the parent hash fetcher
    function sendExactParentHashToL2(bytes calldata _parentHashFetcherCtx) external payable {
        (uint256 parentHashFetchedForBlock, bytes32 parentHash) = parentHashFetcher.fetchParentHash(_parentHashFetcherCtx);
        require(parentHash != bytes32(0), "ERR_INVALID_BLOCK_NUMBER");

        _sendBlockHashToL2(parentHash, parentHashFetchedForBlock);
    }

    /// @param aggregatorId The id of a tree previously created by the aggregators factory
    function sendPoseidonMMRTreeToL2(uint256 aggregatorId, uint256 mmrId) external payable virtual {}

    function _sendBlockHashToL2(bytes32 parentHash_, uint256 blockNumber_) internal {
        uint256[] memory message = new uint256[](4);
        (uint256 parentHashLow, uint256 parentHashHigh) = uint256(parentHash_).split128();
        (uint256 blockNumberLow, uint256 blockNumberHigh) = blockNumber_.split128();
        message[0] = parentHashLow;
        message[1] = parentHashHigh;
        message[2] = blockNumberLow;
        message[3] = blockNumberHigh;

        starknetCore.sendMessageToL2{value: msg.value}(l2RecipientAddr, RECEIVE_COMMITMENT_L1_HANDLER_SELECTOR, message);
    }

    function _sendPoseidonMMRTreeToL2(bytes32 poseidonMMRRoot, uint256 mmrSize, uint256 aggregatorId, uint256 mmrId) internal {
        uint256[] memory message = new uint256[](7);
        (uint256 mmrSizeLow, uint256 mmrSizeHigh) = mmrSize.split128();
        (uint256 aggregatorIdLow, uint256 aggregatorIdHigh) = aggregatorId.split128();
        (uint256 mmrIdLow, uint256 mmrIdHigh) = mmrId.split128();
        message[0] = uint256(poseidonMMRRoot);
        message[1] = mmrSizeLow;
        message[2] = mmrSizeHigh;
        message[3] = aggregatorIdLow;
        message[4] = aggregatorIdHigh;
        message[5] = mmrIdLow;
        message[6] = mmrIdHigh;

        // Pass along msg.value
        starknetCore.sendMessageToL2{value: msg.value}(l2RecipientAddr, RECEIVE_MMR_L1_HANDLER_SELECTOR, message);
    }

    /// @notice Set the L2 recipient address
    /// @param newL2RecipientAddr_ The new L2 recipient address
    function setL2RecipientAddr(uint256 newL2RecipientAddr_) external onlyOwner {
        l2RecipientAddr = newL2RecipientAddr_;
    }

    /// @notice Set the aggregators factory address
    /// @param newAggregatorsFactoryAddr_ The new aggregators factory address
    function setAggregatorsFactoryAddr(address newAggregatorsFactoryAddr_) external onlyOwner {
        aggregatorsFactory = ISharpProofsAggregatorsFactory(newAggregatorsFactoryAddr_);
    }
}
