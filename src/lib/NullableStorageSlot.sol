// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

library NullableStorageSlot {
    function toNullable(uint256 value) internal pure returns (uint256) {
        if (value == type(uint256).max) {
            return value;
        }
        return value + 1;
    }

    function fromNullable(uint256 value) internal pure returns (uint256) {
        require(!NullableStorageSlot.isNull(value), "NullableStorageSlot: value is null");
        if (value == type(uint256).max) {
            return value;
        }
        return value - 1;
    }

    function isNull(uint256 value) internal pure returns (bool) {
        return value == 0;
    }
}
