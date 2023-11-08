// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {AbstractMessagesSender} from "./AbstractMessagesSender.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "./interfaces/IParentHashFetcher.sol";

import {MessagesInbox} from "../MessagesInbox.sol";


contract L1ToL1MessagesSender is AbstractMessagesSender {
    MessagesInbox public immutable messagesInbox;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        IParentHashFetcher _parentHashFetcher,
        address _messagesInbox
    ) AbstractMessagesSender(_proofsAggregatorsFactory, _parentHashFetcher, _messagesInbox) {
        messagesInbox = MessagesInbox(_messagesInbox);
    }

    function _sendMessage(
        address _l2Target,
        bytes memory _data,
        bytes memory _xDomainMsgGasData
    ) internal override {
        // Ensure target is the messages inbox
        require(_l2Target == address(messagesInbox), "Invalid target");
        // As the messages inbox is on L1, check that xDomainMsgGasData is empty
        require(_xDomainMsgGasData.length == 0, "Invalid gas data");
        // Simply invoke the messages inbox with the data
        (bool success, ) = _l2Target.call(_data);
        require(success, "L1ToL1MessagesSender: L1 call failed");
    }
}