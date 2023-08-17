// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FactsRegistry} from "../../core/FactsRegistry.sol";

abstract contract TurboSwapAccounts {
    enum AccountProperty { NONCE, BALANCE, STORAGE_HASH, CODE_HASH }
    struct AccountAttestation {
        uint256 chainId;
        address account;
        uint256 blockNumber;
        AccountProperty property;
    }

    // chainid => block number => address => property => value
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(AccountProperty => bytes32)))) public accountProperty;

    function setMultiple(AccountAttestation[] calldata attestations) external {
        require(msg.sender == _currentAuctionWinner(), "TurboSwap: Only current auction winner can call this function");
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

            accountProperty[attestation.chainId][attestation.blockNumber][attestation.account][attestation.property] = value;
        }
    }

    function clearMultiple(AccountAttestation[] calldata attestations) external {
        require(msg.sender == _currentAuctionWinner(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            AccountAttestation calldata attestation = attestations[i];
            accountProperty[attestation.chainId][attestation.blockNumber][attestation.account][attestation.property] = bytes32(0);
            // TODO pay out fees
        }
    }

    function _getFactRegistryForChain(uint256 chainId) internal virtual view returns(FactsRegistry);

    function _currentAuctionWinner() internal virtual view returns(address);
}