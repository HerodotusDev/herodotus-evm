// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FactsRegistry} from "../../core/FactsRegistry.sol";

import {AccountProperty} from "../interfaces/ITurboSwap.sol";

abstract contract TurboSwapAccounts {
    struct AccountAttestation {
        uint256 chainId;
        address account;
        uint256 blockNumber;
        AccountProperty property;
    }

    // chainid => block number => address => property => value
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(AccountProperty => bytes32)))) internal _accounts;

    function setMultipleAccounts(AccountAttestation[] calldata attestations) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            AccountAttestation calldata attestation = attestations[i];

            FactsRegistry factsRegistry = _getFactRegistryForChain(attestation.chainId);
            require(address(factsRegistry) != address(0), "TurboSwap: Unknown chain id");

            bytes32 value;
            if(attestation.property == AccountProperty.NONCE) {
                value = bytes32(factsRegistry.accountNonces(attestation.account, attestation.blockNumber));
            } else if(attestation.property == AccountProperty.BALANCE) {
                value = bytes32(factsRegistry.accountBalances(attestation.account, attestation.blockNumber));
            } else if(attestation.property == AccountProperty.STORAGE_HASH) {
                value = bytes32(factsRegistry.accountStorageHashes(attestation.account, attestation.blockNumber));
            } else if(attestation.property == AccountProperty.CODE_HASH) {
                value = bytes32(factsRegistry.accountCodeHashes(attestation.account, attestation.blockNumber));
            } else {
                revert("TurboSwap: Unknown property");
            }

            _accounts[attestation.chainId][attestation.blockNumber][attestation.account][attestation.property] = value;
        }
    }

    function clearMultipleAccounts(AccountAttestation[] calldata attestations) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            AccountAttestation calldata attestation = attestations[i];
            _accounts[attestation.chainId][attestation.blockNumber][attestation.account][attestation.property] = bytes32(0);
            // TODO pay out fees
        }
    }

    function _getFactRegistryForChain(uint256 chainId) internal virtual view returns(FactsRegistry);

    function _swapFullfilmentAssignee() internal virtual view returns(address);
}