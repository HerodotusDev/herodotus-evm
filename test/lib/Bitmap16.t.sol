// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";

import {Bitmap16} from "../../src/lib/Bitmap16.sol";

contract Bitmap16Lib_Test is Test {
    using Bitmap16 for uint16;

    function test_readFromRight_16_i0() public {
        uint16 bitmap = 16; // 0b10000
        bool isFirstBitHigh = bitmap.readBitAtIndexFromRight(0);
        assertEq(isFirstBitHigh, false);
    }

    function test_readFromRight_17_i0() public {
        uint16 bitmap = 17; // 0b10001
        bool isFirstBitHigh = bitmap.readBitAtIndexFromRight(0);
        assertEq(isFirstBitHigh, true);
    }

    function test_readFromRight_17_i4() public {
        uint16 bitmap = 17; // 0b10001
        bool isFirstBitHigh = bitmap.readBitAtIndexFromRight(4);
        assertEq(isFirstBitHigh, true);
    }
}
