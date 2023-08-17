// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ISharpProofsAggregator} from "../interfaces/ISharpProofsAggregator.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";


abstract contract AbstractL1MessagesSender {

    ISharpProofsAggregatorsFactory public immutable proofsAggregatorsFactory;
    address public immutable l2Target;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        address _l2Target
    ) {
        proofsAggregatorsFactory = _proofsAggregatorsFactory;
        l2Target = _l2Target;
    }

    /// @notice Send an exact L1 parent hash to L2
    /// @param blockNumber_ the child block of the requested parent hash
    function sendExactParentHashToL2(uint256 blockNumber_, bytes calldata _xDomainMsgGasData) external {
        bytes32 parentHash = blockhash(blockNumber_ - 1);
        require(parentHash != bytes32(0), "ERR_INVALID_BLOCK_NUMBER");
        _sendMessage(l2Target, abi.encode(blockNumber_, parentHash), _xDomainMsgGasData);
    }

    function sendKeccakMMRTreeToL2(uint256 aggregatorId, bytes calldata _xDomainMsgGasData) external {
         address existingAggregatorAddr = proofsAggregatorsFactory.getAggregatorById(
            aggregatorId
        );
        require(existingAggregatorAddr != address(0), "Unknown aggregator");
        ISharpProofsAggregator aggregator = ISharpProofsAggregator(existingAggregatorAddr);

        bytes32 keccakMMRRoot = aggregator.getMMRKeccakRoot();
        uint256 mmrSize = aggregator.getMMRSize();

        // Ensure initialized aggregator
        require(mmrSize >= 1, "Invalid tree size");
        require(keccakMMRRoot != bytes32(0), "Invalid root (Poseidon)");

        _sendMessage(l2Target, abi.encode(aggregatorId, keccakMMRRoot, mmrSize), _xDomainMsgGasData);
    }

    function _sendMessage(
        address _l2Target,
        bytes memory _data,
        bytes memory _xDomainMsgGasData
    ) internal virtual;
}