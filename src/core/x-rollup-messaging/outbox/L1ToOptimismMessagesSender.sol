// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractMessagesSender} from "./AbstractMessagesSender.sol";
import {IOptimismCrossDomainMessenger} from "../interfaces/IOptimismCrossDomainMessenger.sol";
import {ISharpProofsAggregatorsFactory} from "../../interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "../interfaces/IParentHashFetcher.sol";

contract L1ToOptimismMessagesSender is AbstractMessagesSender {
    IOptimismCrossDomainMessenger public immutable optimismMessenger;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        IParentHashFetcher _parentHashFetcher,
        address _l2Target,
        IOptimismCrossDomainMessenger _optimismMessenger
    ) AbstractMessagesSender(_proofsAggregatorsFactory, _parentHashFetcher, _l2Target) {
        optimismMessenger = _optimismMessenger;
    }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal override {
        uint32 l2GasLimit = abi.decode(_xDomainMsgGasData, (uint32));
        optimismMessenger.sendMessage(_l2Target, _data, l2GasLimit);
    }
}
