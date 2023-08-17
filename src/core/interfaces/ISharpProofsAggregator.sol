// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISharpProofsAggregator {
    /// @notice Returns the current root hash of the Keccak Merkle Mountain Range (MMR) tree
    function getMMRKeccakRoot() external view returns (bytes32);

    /// @notice Returns the current root hash of the Poseidon Merkle Mountain Range (MMR) tree
    function getMMRPoseidonRoot() external view returns (bytes32);

    /// @notice Returns the current size of the Merkle Mountain Range (MMR) trees
    function getMMRSize() external view returns (uint256);
}