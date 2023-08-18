// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {TurboSwapStorageSlots} from "./StorageSlots.sol";
import {TurboSwapAccounts} from "./Accounts.sol";
import {TurboSwapHeaders} from "./Headers.sol";


import {FactsRegistry} from "../../core/FactsRegistry.sol";
import {HeadersProcessor} from "../../core/HeadersProcessor.sol";

import {ITurboSwap, AccountProperty, HeaderProperty} from "../interfaces/ITurboSwap.sol";

contract TurboSwap is TurboSwapStorageSlots, TurboSwapAccounts, TurboSwapHeaders, ITurboSwap {
    // chainid => FactsRegistry
    mapping(uint256 => FactsRegistry) public factsRegistries;

    function _swapFullfilmentAssignee() internal override(TurboSwapStorageSlots, TurboSwapAccounts, TurboSwapHeaders) view returns(address) {
        return address(42); // TODO: implement
    }

    function _getFactRegistryForChain(uint256 chainId) internal override(TurboSwapStorageSlots, TurboSwapAccounts) view returns(FactsRegistry) {
        return FactsRegistry(address(42)); // TODO: implement
    }

    function _getHeadersProcessorForChain(uint256 chainId) internal override(TurboSwapHeaders) view returns(HeadersProcessor) {
        return HeadersProcessor(address(42)); // TODO: implement
    }

    function storageSlots(uint256 chainId, uint256 blockNumber, address account, bytes32 slot) external override returns (bytes32) {
        bytes32 value = _storageSlots[chainId][blockNumber][account][slot];
        require(value != bytes32(0), "TurboSwap: Storage slot not set"); // TODO handle case in which it is actually 0
        return value;
    }

    function accounts(uint256 chainId, uint256 blockNumber, address account, AccountProperty property) external override returns (bytes32) {
        bytes32 value = _accounts[chainId][blockNumber][account][property];
        require(value != bytes32(0), "TurboSwap: Account property not set"); // TODO handle case in which it is actually 0
        return value;
    }

    function headers(uint256 chainId, uint256 blockNumber, HeaderProperty property) external override returns (bytes32) {
        bytes32 value = _headers[chainId][blockNumber][property];
        require(value != bytes32(0), "TurboSwap: Header property not set"); // TODO handle case in which it is actually 0
        return value;
    }
}