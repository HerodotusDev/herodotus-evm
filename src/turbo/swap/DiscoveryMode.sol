// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ITurboSwap, AccountProperty} from "../interfaces/ITurboSwap.sol";

contract TurboSwapDiscoveryMode is ITurboSwap {
    struct StorageSlotAttestion {
        uint256 chainId;
        uint256 blockNumber;
        address account;
        bytes32 slot;
        bytes32 value;
    }

    struct AccountAttestation {
        uint256 chainId;
        uint256 blockNumber;
        address account;
        AccountProperty property;
        bytes32 value;
    }

    function accounts(uint256 chainId, uint256 blockNumber, address account, AccountProperty property) external returns (bytes32) {
        // TODO emit events
        return bytes32(0);
    }

    function storageSlots(uint256 chainId, uint256 blockNumber, address account, bytes32 slot) external returns (bytes32) {
        // TODO emit events
        return bytes32(0);
    }

    function setMultipleAccounts(AccountAttestation[] calldata attestations) external {
        // TODO: implement setting
        revert("TurboSwap: Discovery mode");
    }

    function setMultipleStorageSlots(StorageSlotAttestion[] calldata attestations) external {
        // TODO: implement setting
        revert("TurboSwap: Discovery mode");
    }
}