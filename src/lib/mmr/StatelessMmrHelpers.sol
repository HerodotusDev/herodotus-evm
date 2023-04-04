// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StatelessMmrHelpers {
    function isPeak(uint256 num, uint256[] calldata peaks) internal pure returns (bool) {
        for (uint256 i = 0; i < peaks.length; ++i) {
            if (peaks[i] == num) {
                return true;
            }
        }
        return false;
    }

    function peakMapHeight(uint256 size) internal pure returns (uint256, uint256) {
        if (size == 0) {
            return (0, 0);
        }
        uint256 peak_size = type(uint256).max >> leadingZeros(size);
        uint256 peak_map = 0;
        while (peak_size != 0) {
            peak_map <<= 1;
            if (size >= peak_size) {
                size -= peak_size;
                peak_map |= 1;
            }
            peak_size >>= 1;
        }
        return (peak_map, size);
    }

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

    function allOnes(uint256 num) internal pure returns (bool) {
        return (1 << bitLength(num)) - 1 == num;
    }

    function leadingZeros(uint256 num) internal pure returns (uint256) {
        return num == 0 ? 64 : 64 - bitLength(num);
    }

    function getHeight(uint256 num) internal pure returns (uint256) {
        uint256 h = num;

        // Travel left until reaching leftmost branch (all bits set to 1)
        while (!allOnes(h)) {
            h = h - ((1 << (bitLength(h) - 1)) - 1);
        }
        return bitLength(h) - 1;
    }

    function siblingOffset(uint256 height) internal pure returns (uint256) {
        return (2 << height) - 1;
    }

    function parentOffset(uint256 height) internal pure returns (uint256) {
        return 2 << height;
    }

    function bintreeJumpRightSibling(uint256 num) internal pure returns (uint256) {
        uint256 height = getHeight(num);
        return num + (1 << (height + 1)) - 1;
    }

    function bintreeMoveDownLeft(uint256 num) internal pure returns (uint256) {
        uint256 height = getHeight(num);
        if (height == 0) {
            return 0;
        }
        return num - (1 << height);
    }
}
