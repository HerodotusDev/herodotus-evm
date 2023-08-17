// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {HeadersProcessor} from "../../core/HeadersProcessor.sol";

// TODO: implement
abstract contract TurboSwapHeaders {
    function _swapFullfilmentAssignee() internal virtual view returns(address);
}