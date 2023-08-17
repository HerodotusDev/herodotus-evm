// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

enum AccountProperty { NONCE, BALANCE, STORAGE_HASH, CODE_HASH }

interface ITurboSwap {
    function storageSlots(uint256 chainId, uint256 blockNumber, address account, bytes32 slot) external returns (bytes32);

    function accounts(uint256 chainId, uint256 blockNumber, address account, AccountProperty property) external returns (bytes32);
}