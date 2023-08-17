// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FactsRegistry} from "../../core/FactsRegistry.sol";

abstract contract TurboSwapStorageSlots {
    struct StorageSlotAttestation {
        uint256 chainId;
        address account;
        uint256 blockNumber;
        bytes32 slot;
    }

    // chainid => block number => address => slot => value
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(bytes32 => bytes32)))) public storageSlots;

    function setMultiple(StorageSlotAttestation[] calldata attestations) external {
        require(msg.sender == _currentAuctionWinner(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            StorageSlotAttestation calldata attestation = attestations[i];

            FactsRegistry factsRegistry = _getFactRegistryForChain(attestation.chainId);
            require(address(factsRegistry) != address(0), "TurboSwap: Unknown chain id");

            bytes32 value = factsRegistry.accountStorageSlotValues(attestation.account, attestation.blockNumber, attestation.slot);
            storageSlots[attestation.chainId][attestation.blockNumber][attestation.account][attestation.slot] = value;
        }
    }

    function clearMultiple(StorageSlotAttestation[] calldata attestations) external {
        require(msg.sender == _currentAuctionWinner(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            StorageSlotAttestation calldata attestation = attestations[i];
            storageSlots[attestation.chainId][attestation.blockNumber][attestation.account][attestation.slot] = bytes32(0);
            // TODO pay out fees
        }
    }

    function _currentAuctionWinner() internal virtual view returns(address);

    function _getFactRegistryForChain(uint256 chainId) internal virtual view returns(FactsRegistry);
}