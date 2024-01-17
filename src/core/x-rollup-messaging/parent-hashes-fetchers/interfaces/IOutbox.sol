// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IOutbox {
    // TODO: Can we use this struct to validate the output root?
    // // we're packing this struct into 4 storage slots
    // // 1st slot: timestamp, l2Block (128 bits each, max ~3.4*10^38)
    // // 2nd slot: outputId (256 bits)
    // // 3rd slot: l1Block (96 bits, max ~7.9*10^28), sender (address 160 bits)
    // // 4th slot: withdrawalAmount (256 bits)
    // struct L2ToL1Context {
    //     uint128 l2Block;
    //     uint128 timestamp;
    //     bytes32 outputId;
    //     address sender;
    //     uint96 l1Block;
    //     uint256 withdrawalAmount;
    // }
    
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