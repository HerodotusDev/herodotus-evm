// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from "forge-std/console.sol";

library StatelessMmrHelpers {
    // Returns the number of bits in `num`
    function bitLength(uint256 num) internal pure returns (uint256) {
        require(num >= 0, "num must be greater than or equal to zero");

        uint256 bitPosition = 0;
        uint256 curN = 1;
        while (num >= curN) {
            bitPosition += 1;
            curN <<= 1;
        }
        return bitPosition;
    }

    // Returns a number having all its bits set to 1 for a given `bitsLength`
    function allOnes(uint256 bitsLength) internal pure returns (uint256) {
        require(bitsLength > 0, "bitLen must be greater than zero");
        return (1 << bitsLength) - 1;
    }

    // Returns the sibling offset from `height`
    function siblingOffset(uint256 height) internal pure returns (uint256) {
        return (2 << height) - 1;
    }

    // Returns the parent offset from `height`
    function parentOffset(uint256 height) internal pure returns (uint256) {
        return 2 << height;
    }

    function newArrWithElem(bytes32[] memory sourceArr, bytes32 elem) internal pure returns (bytes32[] memory) {
        bytes32[] memory outputArray = new bytes32[](sourceArr.length + 1);
        uint i = 0;
        for (; i < sourceArr.length; i++) {
            outputArray[i] = sourceArr[i];
        }
        outputArray[i] = elem;
        return outputArray;
    }
}
