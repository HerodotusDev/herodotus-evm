// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractL1ToL3MessagesSender} from "./AbstractL1ToL3MessagesSender.sol";
import {IArbitrumInbox} from "../interfaces/IArbitrumInbox.sol";
import {ISharpProofsAggregatorsFactory} from "../../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";

contract L1ToApeChainMessagesSender is AbstractL1ToL3MessagesSender {
    IArbitrumInbox public immutable arbitrumInbox;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        IParentHashFetcher _parentHashFetcher,
        address _l2Target,
        address _l3Target,
        IArbitrumInbox _arbitrumInbox
    ) AbstractL1ToL3MessagesSender(_proofsAggregatorsFactory, _parentHashFetcher, _l2Target, _l3Target) {
        arbitrumInbox = _arbitrumInbox;
    }

    function _sendMessage(address _l2Target, address _l3Target, bytes memory _data, bytes memory _xDomainL2MsgGasData, bytes memory _xDomainL3MsgGasData) internal override {
        (uint256 l2GasLimit, uint256 l2MaxFeePerGas, uint256 l2MaxSubmissionCost) = abi.decode(_xDomainL2MsgGasData, (uint256, uint256, uint256));

        (uint256 l3GasLimit, uint256 l3MaxFeePerGas, uint256 l3MaxSubmissionCost, uint256 tokenTotalFeeAmount) = abi.decode(
            _xDomainL3MsgGasData,
            (uint256, uint256, uint256, uint256)
        );

        bytes memory l2ToL3Message = abi.encodeWithSignature(
            "forwardMessageToApeChain(address,uint256,uint256,uint256,uint256,bytes)",
            _l3Target,
            l3MaxSubmissionCost,
            l3GasLimit,
            l3MaxFeePerGas,
            tokenTotalFeeAmount,
            _data
        );

        arbitrumInbox.createRetryableTicket{value: msg.value}(_l2Target, 0, l2MaxSubmissionCost, msg.sender, address(0), l2GasLimit, l2MaxFeePerGas, l2ToL3Message);
    }
}
