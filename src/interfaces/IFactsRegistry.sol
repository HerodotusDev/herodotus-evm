// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFactsRegistry {
    function proveAccount(
        uint16 paramsBitmap,
        uint256 blockNumber,
        address account,
        bytes calldata proof
    ) external;

    function accountNonces(address account, uint256 blockNumber) external view returns (uint256);

    function accountBalances(address account, uint256 blockNumber) external view returns (uint256);

    function accountCodeHashes(address account, uint256 blockNumber) external view returns (bytes32);

    function accountStorageHashes(address account, uint256 blockNumber) external view returns (bytes32);
}
