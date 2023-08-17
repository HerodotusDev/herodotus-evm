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

    // chainid => FactsRegistry
    mapping(uint256 => FactsRegistry) public factsRegistries;

    // chainid => block number => address => slot => value
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(bytes32 => bytes32)))) public storageSlots;

    modifier onlyCurrentAuctionWinner() {
        require(msg.sender == _currentAuctionWinner(), "TurboSwap: Only current auction winner can call this function");
        _;
    }


    function setMultiple(StorageSlotAttestation[] calldata attestations) external onlyCurrentAuctionWinner {
        for(uint256 i = 0; i < attestations.length; i++) {
            StorageSlotAttestation calldata attestation = attestations[i];
            require(address(factsRegistries[attestation.chainId]) != address(0), "TurboSwap: Unknown chain id");
            bytes32 value = factsRegistries[attestation.chainId].accountStorageSlotValues(attestation.account, attestation.blockNumber, attestation.slot);
            storageSlots[attestation.chainId][attestation.blockNumber][attestation.account][attestation.slot] = value;
        }
    }

    function clearMultiple(StorageSlotAttestation[] calldata attestations) external onlyCurrentAuctionWinner {
        for(uint256 i = 0; i < attestations.length; i++) {
            StorageSlotAttestation calldata attestation = attestations[i];
            require(address(factsRegistries[attestation.chainId]) != address(0), "TurboSwap: Unknown chain id");
            storageSlots[attestation.chainId][attestation.blockNumber][attestation.account][attestation.slot] = bytes32(0);
            // TODO pay out fees
        }
    }

    function _currentAuctionWinner() internal virtual view returns(address);
}