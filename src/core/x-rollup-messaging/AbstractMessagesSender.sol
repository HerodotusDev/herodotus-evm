// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ISharpProofsAggregator} from "../interfaces/ISharpProofsAggregator.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "./interfaces/IParentHashFetcher.sol";

abstract contract AbstractMessagesSender {
    ISharpProofsAggregatorsFactory public immutable proofsAggregatorsFactory;
    IParentHashFetcher public immutable parentHashFetcher;
    address public immutable l2Target;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        IParentHashFetcher _parentHashFetcher,
        address _l2Target
    ) {
        proofsAggregatorsFactory = _proofsAggregatorsFactory;
        parentHashFetcher = _parentHashFetcher;
        l2Target = _l2Target;
    }

    /// @notice Send an exact L1 parent hash to L2
    /// @param _parentHashFetcherCtx ABI encoded context for the parent hash fetcher
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination L2
    function sendExactParentHashToL2(bytes calldata _parentHashFetcherCtx, bytes calldata _xDomainMsgGasData)
        external
    {
        (uint256 parentHashFetchedForBlock, bytes32 parentHash) =
            parentHashFetcher.fetchParentHash(_parentHashFetcherCtx);
        require(parentHash != bytes32(0), "ERR_INVALID_BLOCK_NUMBER");
        _sendMessage(
            l2Target,
            abi.encodeWithSignature("receiveParentHashForBlock(uint256,bytes32)", parentHashFetchedForBlock, parentHash),
            _xDomainMsgGasData
        );
    }

    function sendKeccakMMRTreeToL2(uint256 aggregatorId, bytes calldata _xDomainMsgGasData) external {
        address existingAggregatorAddr = proofsAggregatorsFactory.aggregatorsById(aggregatorId);
        require(existingAggregatorAddr != address(0), "Unknown aggregator");
        ISharpProofsAggregator aggregator = ISharpProofsAggregator(existingAggregatorAddr);

        bytes32 keccakMMRRoot = aggregator.getMMRKeccakRoot();
        uint256 mmrSize = aggregator.getMMRSize();

        // Ensure initialized aggregator
        require(mmrSize >= 1, "Invalid tree size");
        require(keccakMMRRoot != bytes32(0), "Invalid root (keccak)");

        _sendMessage(
            l2Target,
            abi.encodeWithSignature("receiveKeccakMMR(uint256,uint256,bytes32)", aggregatorId, mmrSize, keccakMMRRoot),
            _xDomainMsgGasData
        );
    }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal virtual;
}
