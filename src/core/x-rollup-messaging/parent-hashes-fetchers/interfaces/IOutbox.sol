// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IOutbox {
    function roots(bytes32) external view returns (bytes32);// maps root hashes => L2 block hash
    function calculateItemHash(
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes32);

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) external pure returns (bytes32);
}