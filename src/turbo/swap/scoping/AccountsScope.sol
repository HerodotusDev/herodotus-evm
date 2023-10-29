// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FactsRegistry} from "../../../core/FactsRegistry.sol";

import {Types} from "../../../lib/Types.sol";

abstract contract TurboSwapAccounts {
    struct AccountAttestation {
        uint256 chainId;
        address account;
        uint256 blockNumber;
        Types.AccountFields field;
    }

    // chainid => block number => address => property => value
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(Types.AccountFields => bytes32)))) internal _accounts;

    function setMultipleAccounts(AccountAttestation[] calldata attestations) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            AccountAttestation calldata attestation = attestations[i];

            FactsRegistry factsRegistry = _getFactRegistryForChain(attestation.chainId);
            require(address(factsRegistry) != address(0), "TurboSwap: Unknown chain id");

            bytes32 value = factsRegistry.accountField(attestation.account, attestation.blockNumber, attestation.field);
            _accounts[attestation.chainId][attestation.blockNumber][attestation.account][attestation.field] = value;
        }
    }

    function clearMultipleAccounts(AccountAttestation[] calldata attestations) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            AccountAttestation calldata attestation = attestations[i];
            _accounts[attestation.chainId][attestation.blockNumber][attestation.account][attestation.field] = bytes32(0);
            // TODO pay out fees
        }
    }

    function _getFactRegistryForChain(uint256 chainId) internal virtual view returns(FactsRegistry);

    function _swapFullfilmentAssignee() internal virtual view returns(address);
}