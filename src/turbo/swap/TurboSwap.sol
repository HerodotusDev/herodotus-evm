// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {TurboSwapStorageSlots} from "./StorageSlots.sol";
import {TurboSwapAccounts} from "./Accounts.sol";
import {TurboSwapHeaders} from "./Headers.sol";


import {FactsRegistry} from "../../core/FactsRegistry.sol";

contract TurboSwap is TurboSwapStorageSlots, TurboSwapAccounts, TurboSwapHeaders {
    // chainid => FactsRegistry
    mapping(uint256 => FactsRegistry) public factsRegistries;

    function _currentAuctionWinner() internal override(TurboSwapStorageSlots, TurboSwapAccounts, TurboSwapHeaders) view returns(address) {
        return address(42); // TODO: implement
    }

    function _getFactRegistryForChain(uint256 chainId) internal override(TurboSwapStorageSlots, TurboSwapAccounts) view returns(FactsRegistry) {
        return FactsRegistry(address(42)); // TODO: implement
    }
}