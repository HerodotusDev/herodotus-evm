// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {TurboSwapStorageSlots} from "./StorageSlots.sol";

contract TurboSwap is TurboSwapStorageSlots {
    function _currentAuctionWinner() internal view override returns(address) {
        return address(42); // TODO: implement
    }
}