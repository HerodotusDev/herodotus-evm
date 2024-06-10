// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Uint256Splitter {
    uint256 constant _MASK = type(uint128).max;

    /// @notice Splits a uint256 into two uint128s (low, high) represented as uint256s.
    /// @param a The uint256 to split.
    function split128(
        uint256 a
    ) internal pure returns (uint256 lower, uint256 upper) {
        return (a & _MASK, a >> 128);
    }

    /// @notice Merges two uint128s (low, high) into one uint256.
    /// @param lower The lower uint256. The caller is required to pass a value that is less than 2^128 - 1.
    /// @param upper The upper uint256.
    function merge128(
        uint256 lower,
        uint256 upper
    ) internal pure returns (uint256 a) {
        require(lower <= _MASK, "Uint256Splitter: lower exceeds uint128");
        // return (upper << 128) | lower;
        assembly {
            a := or(shl(128, upper), lower)
        }
    }
}
