// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


import {AbstractL1MessagesSender} from "./AbstractL1MessagesSender.sol";
import {IOptimismCrossDomainMessenger} from "./interfaces/IOptimismCrossDomainMessenger.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";


contract L1MessagesSenderToOptimism is AbstractL1MessagesSender {
    IOptimismCrossDomainMessenger public immutable optimismMessenger;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        address _l2Target,
        IOptimismCrossDomainMessenger _optimismMessenger
    ) AbstractL1MessagesSender(_proofsAggregatorsFactory, _l2Target) {
        optimismMessenger = _optimismMessenger;
    }

    function _sendMessage(
        address _l2Target,
        bytes memory _data,
        bytes memory _xDomainMsgGasData
    ) internal override {
        (uint32 l2GasLimit) = abi.decode(
            _xDomainMsgGasData,
            (uint32)
        );
        optimismMessenger.sendMessage(_l2Target, _data, l2GasLimit);
    }
}