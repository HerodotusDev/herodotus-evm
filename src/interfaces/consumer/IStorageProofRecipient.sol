// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStorageProofRecipient {
    struct StorageContext {
        uint256 blockNumber;
        address account;
        bytes32 slot;
        bytes32 value;
    }

    struct StorageContextMultiple {
        uint256 blockNumber;
        address account;
        bytes32[] slots;
        bytes32[] values;
    }

    function consumeStorageProof(StorageContext calldata storageCtx, bytes calldata additionalCtx) external;

    function consumeStorageProofs(StorageContextMultiple calldata storageCtx, bytes calldata additionalCtx) external;
}
