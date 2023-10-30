// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;


library Nullable { 
    function toNullable(uint256 value) internal pure returns (uint256) {
        if (value == type(uint256).max) {
            return value;
        }
        return value + 1;
    }

    function fromNullable(uint256 value) internal pure returns (uint256) {
        require(!Nullable.isNull(value), "Nullable: value is null");
        if (value == type(uint256).max) {
            return value;
        }
        return value - 1;
    }

    function isNull(uint256 value) internal pure returns (bool) {
        return value == 0;
    }
}