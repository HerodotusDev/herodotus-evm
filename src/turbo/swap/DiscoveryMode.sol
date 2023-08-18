// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {TurboSwapStorageSlots} from "./StorageSlots.sol";
import {TurboSwapAccounts} from "./Accounts.sol";
import {TurboSwapHeaders} from "./Headers.sol";


import {FactsRegistry} from "../../core/FactsRegistry.sol";
import {HeadersProcessor} from "../../core/HeadersProcessor.sol";

import {ITurboSwap, AccountProperty, HeaderProperty} from "../interfaces/ITurboSwap.sol";


// This contract will be the implementation behind the proxy, so it will have access to the state of the actual swap.
contract TurboSwapDiscoveryMode is TurboSwapStorageSlots, TurboSwapAccounts, TurboSwapHeaders, ITurboSwap {
    event IdentifiedUnsetStorageSlot(uint256 chainId, uint256 blockNumber, address account, bytes32 slot);
    event IdentifiedUnsetAccountProperty(uint256 chainId, uint256 blockNumber, address account, AccountProperty property);
    event IdentifiedUnsetHeaderProperty(uint256 chainId, uint256 blockNumber, HeaderProperty property);

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
        if(value == bytes32(0)) { // TODO handle case in which it is actually 0
            emit IdentifiedUnsetStorageSlot(chainId, blockNumber, account, slot);
        }
        return value;
    }

    function accounts(uint256 chainId, uint256 blockNumber, address account, AccountProperty property) external override returns (bytes32) {
        bytes32 value = _accounts[chainId][blockNumber][account][property];
        if(value == bytes32(0)) { // TODO handle case in which it is actually 0
            emit IdentifiedUnsetAccountProperty(chainId, blockNumber, account, property);
        }
        return value;
    }

    function headers(uint256 chainId, uint256 blockNumber, HeaderProperty property) external override returns (bytes32) {
        bytes32 value = _headers[chainId][blockNumber][property];
        if(value == bytes32(0)) { // TODO handle case in which it is actually 0
            emit IdentifiedUnsetHeaderProperty(chainId, blockNumber, property);
        }
        return value;
    }
}