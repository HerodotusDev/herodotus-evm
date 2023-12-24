// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;


library NullableStorageSlot {
    uint256 private constant VAL_NULL_UINT = type(uint256).max;

    function toNullable(uint256 value) internal pure returns (uint256) {
        if (value == VAL_NULL_UINT) {
            return value;
        }
        return value + 1;
    }

    function fromNullable(uint256 value) internal pure returns (uint256) {
        require(!NullableStorageSlot.isNull(value), "NullableStorageSlot: value is null");
        if (value == VAL_NULL_UINT) {
            return value;
        }
        return value - 1;
    }

    function isNull(uint256 value) internal pure returns (bool) {
        return value == 0;
    }
}