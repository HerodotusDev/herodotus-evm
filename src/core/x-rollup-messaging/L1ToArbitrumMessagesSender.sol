// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractMessagesSender} from "./AbstractMessagesSender.sol";
import {IArbitrumInbox} from "./interfaces/IArbitrumInbox.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "./interfaces/IParentHashFetcher.sol";

contract L1ToArbitrumMessageSender is AbstractMessagesSender {
    IArbitrumInbox public immutable arbitrumInbox;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        IParentHashFetcher _parentHashFetcher,
        address _l2Target,
        IArbitrumInbox _arbitrumInbox
    ) AbstractMessagesSender(_proofsAggregatorsFactory, _parentHashFetcher, _l2Target) {
        arbitrumInbox = _arbitrumInbox;
    }
    
    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal override {
        (uint256 l2GasLimit, uint256 maxFeePerGas) = abi.decode(_xDomainMsgGasData, (uint256,uint256));
        // TODO : check if this is correct way to send message to arbitrum
        arbitrumInbox.createRetryableTicket(
            _l2Target, 0, 0, msg.sender, msg.sender, l2GasLimit, maxFeePerGas, _data
        );
    }
}