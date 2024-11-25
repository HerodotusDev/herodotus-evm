// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ISharpProofsAggregator} from "../../interfaces/ISharpProofsAggregator.sol";
import {ISharpProofsAggregatorsFactory} from "../../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";

abstract contract AbstractL1ToL3MessagesSender {
    ISharpProofsAggregatorsFactory public immutable proofsAggregatorsFactory;
    IParentHashFetcher public immutable parentHashFetcher;
    address public immutable l2Target;
    address public immutable l3Target;

    constructor(ISharpProofsAggregatorsFactory _proofsAggregatorsFactory, IParentHashFetcher _parentHashFetcher, address _l2Target, address _l3Target) {
        proofsAggregatorsFactory = _proofsAggregatorsFactory;
        parentHashFetcher = _parentHashFetcher;
        l2Target = _l2Target;
        l3Target = _l3Target;
    }

    /// @notice Send an exact L1 parent hash to L3
    /// @param _parentHashFetcherCtx ABI encoded context for the parent hash fetcher
    /// @param _xDomainL2MsgGasData the gas data for the cross-domain message, depends on the destination L2
    /// @param _xDomainL3MsgGasData the gas data for the cross-domain message, depends on the destination L3
    function sendExactParentHashToL3(bytes calldata _parentHashFetcherCtx, bytes memory _xDomainL2MsgGasData, bytes memory _xDomainL3MsgGasData) external payable {
        (uint256 parentHashFetchedForBlock, bytes32 parentHash) = parentHashFetcher.fetchParentHash(_parentHashFetcherCtx);
        require(parentHash != bytes32(0), "ERR_INVALID_BLOCK_NUMBER");
        _sendMessage(
            l2Target,
            l3Target,
            abi.encodeWithSignature("receiveHashForBlock(uint256,bytes32)", parentHashFetchedForBlock, parentHash),
            _xDomainL2MsgGasData,
            _xDomainL3MsgGasData
        );
    }

    function sendKeccakMMRTreeToL3(uint256 aggregatorId, uint256 newMmrId, bytes memory _xDomainL2MsgGasData, bytes memory _xDomainL3MsgGasData) external payable {
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
            l3Target,
            abi.encodeWithSignature("receiveKeccakMMR(uint256,uint256,bytes32,uint256)", aggregatorId, mmrSize, keccakMMRRoot, newMmrId),
            _xDomainL2MsgGasData,
            _xDomainL3MsgGasData
        );
    }

    function _sendMessage(address _l2Target, address _l3Target, bytes memory _data, bytes memory _xDomainL2MsgGasData, bytes memory _xDomainL3MsgGasData) internal virtual;
}
