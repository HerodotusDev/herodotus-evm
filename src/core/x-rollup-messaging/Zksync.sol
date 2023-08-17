// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {AbstractL1MessagesSender} from "./AbstractL1MessagesSender.sol";
import {IZkSyncMailbox} from "./interfaces/IZkSyncMailbox.sol";
import {ISharpProofsAggregatorsFactory} from "../interfaces/ISharpProofsAggregatorsFactory.sol";

contract L1MessagesSenderToZkSync is AbstractL1MessagesSender {

    IZkSyncMailbox public immutable zksyncMailbox;

    constructor(
        ISharpProofsAggregatorsFactory _proofsAggregatorsFactory,
        address _l2Target,
        IZkSyncMailbox _zksyncMailbox
    ) AbstractL1MessagesSender(_proofsAggregatorsFactory, _l2Target) {
        zksyncMailbox = _zksyncMailbox;
    }

    function _sendMessage(
        address _l2Target,
        bytes memory _data,
        bytes memory _xDomainMsgGasData
    ) internal override {
        (uint256 l2GasLimit, uint256 l2GasPerPubdataByteLimit) = abi.decode(
            _xDomainMsgGasData,
            (uint256, uint256)
        );
        zksyncMailbox.requestL2Transaction(_l2Target, 0, _data, l2GasLimit, l2GasPerPubdataByteLimit, new bytes[](0), msg.sender);
    }
}