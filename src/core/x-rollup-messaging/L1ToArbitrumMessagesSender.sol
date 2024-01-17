// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractMessagesSender} from "./AbstractMessagesSender.sol";
import {IOutbox} from "./interfaces/IOutbox.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "./interfaces/IParentHashFetcher.sol";

contract L1ToArbitrumMessageSender is AbstractMessagesSender {
    IOutbox public immutable outbox;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        IParentHashFetcher _parentHashFetcher,
        address _l2Target,
        IOutbox _outbox
    ) AbstractMessagesSender(_proofsAggregatorsFactory, _parentHashFetcher, _l2Target) {
        outbox = _outbox;
    }
    
    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal override {
        (uint256 l2GasLimit) = abi.decode(_xDomainMsgGasData, (uint256));
        // TODO : check if this is correct way to send message
        outbox.executeTransaction{gas: l2GasLimit}(
            new bytes32[](0),
            0,
            msg.sender,
            _l2Target,
            0,
            0,
            0,
            0,
            _data
        );
    }
}