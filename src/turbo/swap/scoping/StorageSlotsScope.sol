// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {FactsRegistry} from "../../../core/FactsRegistry.sol";

abstract contract TurboSwapStorageSlots {
    struct StorageSlotAttestation {
        uint256 chainId;
        address account;
        uint256 blockNumber;
        bytes32 slot;
    }

    // chainid => block number => address => slot => value
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(bytes32 => bytes32)))) internal _storageSlots;

    function setMultipleStorageSlots(StorageSlotAttestation[] calldata attestations) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            StorageSlotAttestation calldata attestation = attestations[i];

            FactsRegistry factsRegistry = _getFactRegistryForChain(attestation.chainId);
            require(address(factsRegistry) != address(0), "TurboSwap: Unknown chain id");

            bytes32 value = factsRegistry.accountStorageSlotValues(attestation.account, attestation.blockNumber, attestation.slot);
            _storageSlots[attestation.chainId][attestation.blockNumber][attestation.account][attestation.slot] = value;
        }
    }

    function clearMultipleStorageSlots(StorageSlotAttestation[] calldata attestations) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            StorageSlotAttestation calldata attestation = attestations[i];
            _storageSlots[attestation.chainId][attestation.blockNumber][attestation.account][attestation.slot] = bytes32(0);
            // TODO pay out fees
        }
    }

    function _swapFullfilmentAssignee() internal virtual view returns(address);

    function _getFactRegistryForChain(uint256 chainId) internal virtual view returns(FactsRegistry);
}