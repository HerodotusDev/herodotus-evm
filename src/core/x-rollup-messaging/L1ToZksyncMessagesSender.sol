// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractMessagesSender} from "./AbstractMessagesSender.sol";
import {IZkSyncMailbox} from "./interfaces/IZkSyncMailbox.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "./interfaces/IParentHashFetcher.sol";

contract L1ToZkSyncMessagesSender is AbstractMessagesSender {
    IZkSyncMailbox public immutable zksyncMailbox;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        IParentHashFetcher _parentHashFetcher,
        address _l2Target,
        IZkSyncMailbox _zksyncMailbox
    ) AbstractMessagesSender(_proofsAggregatorsFactory, _parentHashFetcher, _l2Target) {
        zksyncMailbox = _zksyncMailbox;
    }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal override {
        (uint256 l2GasLimit, uint256 l2GasPerPubdataByteLimit) = abi.decode(_xDomainMsgGasData, (uint256, uint256));
        zksyncMailbox.requestL2Transaction(_l2Target, 0, _data, l2GasLimit, l2GasPerPubdataByteLimit, new bytes[](0), msg.sender);
    }
}
