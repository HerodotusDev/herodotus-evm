// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import "./StatelessMmrHelpers.sol";

/**
 * @title StatelessMmr -- A Solidity implementation of Merkle Mountain Range.
 * @author Herodotus Ltd
 * @notice Library to append elements on-chain (i.e., acting as an accumulator) and verify off-chain generated proofs.
 */
library StatelessMmr {
    function append(uint elem, bytes32[] memory peaks, uint lastPos, bytes32 lastRoot) internal pure returns (uint, bytes32, bytes32[] memory) {
        uint newPos = lastPos + 1;
        if (lastPos == 0) {
            bytes32 root0 = keccak256(abi.encodePacked(uint(1), elem));
            bytes32 firstRoot = keccak256(abi.encodePacked(uint(1), root0));
            bytes32[] memory newPeaks = StatelessMmrHelpers.newArrWithElem(peaks, root0);
            return (newPos, firstRoot, newPeaks);
        }

        bytes32 computedRoot = computeRoot(peaks, lastPos);
        require(computedRoot == lastRoot, "Invalid root");

        bytes32 hash = keccak256(abi.encodePacked(newPos, elem));
        bytes32[] memory appendPeaks = StatelessMmrHelpers.newArrWithElem(peaks, hash);
        (bytes32[] memory updatedPeaks, uint updatedPos) = appendRec(0, appendPeaks, newPos);
        bytes32 newRoot = computeRoot(updatedPeaks, updatedPos);
        return (updatedPos, newRoot, updatedPeaks);
    }

    function appendRec(uint h, bytes32[] memory peaks, uint lastPos) internal pure returns (bytes32[] memory, uint) {
        uint newPos = lastPos;
        uint nextHeight = height(newPos + 1);

        bool isHigher = h + 1 <= nextHeight;
        if (isHigher) {
            newPos = newPos + 1;

            bytes32 rightHash = peaks[peaks.length - 1];
            bytes32 leftHash = peaks[peaks.length - 2];

            bytes32 hash = keccak256(abi.encodePacked(leftHash, rightHash));
            bytes32 parentHash = keccak256(abi.encodePacked(newPos, hash));
            bytes32[] memory mergedPeaks = StatelessMmrHelpers.newArrWithElem(peaks, parentHash);

            return appendRec(h + 1, mergedPeaks, newPos);
        }

        return (peaks, newPos);
    }

    function computeRoot(bytes32[] memory peaks, uint size) internal pure returns (bytes32) {
        bytes32 baggedPeaks = bagPeaks(peaks);
        return keccak256(abi.encodePacked(size, baggedPeaks));
    }

    function bagPeaks(bytes32[] memory peaks) internal pure returns (bytes32) {
        require(peaks.length >= 1, "peaksLen must be at least 1");

        if (peaks.length == 1) {
            return peaks[0];
        }

        bytes32 bags = peaks[peaks.length - 1];
        for (int256 i = int256(peaks.length - 1); i >= 0; --i) {
            bags = keccak256(abi.encodePacked(bags, peaks[uint(i)]));
        }
        return bags;
    }

    function height(uint index) internal pure returns (uint) {
        require(index >= 1, "index must be at least 1");

        uint bits = StatelessMmrHelpers.bitLength(index);
        uint ones = StatelessMmrHelpers.allOnes(bits);

        if (index != ones) {
            uint shifted = 1 << (bits - 1);
            uint recHeight = height(index - (shifted - 1));
            return recHeight;
        }

        return bits - 1;
    }
}
