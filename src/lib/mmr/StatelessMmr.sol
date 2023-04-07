// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";

import "./StatelessMmrHelpers.sol";

/**
 * @title StatelessMmr -- A Solidity implementation of Merkle Mountain Range
 * @author Herodotus Ltd
 * @notice Library for appending elements (i.e., acting as an accumulator) and verifying proofs
 */
library StatelessMmr {
    function verifyProof(uint index, bytes32 value, bytes32[] memory proof, bytes32[] memory peaks, uint pos, bytes32 root) internal pure {
        require(index >= 0, "index must be greater or equal to 0");
        require(index <= pos, "index must be less or equal to pos");

        bytes32 computedRoot = computeRoot(peaks, bytes32(pos));
        require(computedRoot == root, "invalid root");

        bytes32 hash = keccak256(abi.encode(index, value));

        bytes32 peak = getProofTopPeak(0, hash, index, proof);
        bool isValid = StatelessMmrHelpers.arrayContains(peak, peaks);
        assert(isValid == true);
    }

    function getProofTopPeak(uint h, bytes32 hash, uint pos, bytes32[] memory proof) internal pure returns (bytes32) {
        for (uint i = 0; i < proof.length; ++i) {
            bytes32 currentSibling = proof[i];
            uint nextHeight = height(pos + 1);

            bool isHigher = h + 1 <= nextHeight;
            if (isHigher) {
                // Right child
                bytes32 hashed = keccak256(abi.encode(currentSibling, hash));
                pos += 1;

                bytes32 parentHash = keccak256(abi.encode(pos, hashed));
                hash = parentHash;
            } else {
                // Left child
                bytes32 hashed = keccak256(abi.encode(hash, currentSibling));
                pos += 2 << h;

                bytes32 parentHash = keccak256(abi.encode(pos, hashed));
                hash = parentHash;
            }
            ++h; // Increase height
        }
        return hash;
    }

    function multiAppend(bytes32[] memory elems, bytes32[] memory peaks, uint lastPos, bytes32 lastRoot) internal pure returns (uint, bytes32) {
        uint pos = lastPos;
        bytes32 root = lastRoot;
        bytes32[] memory updatedPeaks = peaks;
        for (uint i = 0; i < elems.length; ++i) {
            (pos, root, updatedPeaks) = appendWithPeaksRetrieval(elems[i], updatedPeaks, pos, root);
        }
        return (pos, root);
    }

    function appendWithPeaksRetrieval(bytes32 elem, bytes32[] memory peaks, uint lastPos, bytes32 lastRoot) internal pure returns (uint, bytes32, bytes32[] memory) {
        uint pos = lastPos + 1;
        if (lastPos == 0) {
            bytes32 root0 = keccak256(abi.encode(uint(1), elem));
            bytes32 firstRoot = keccak256(abi.encode(uint(1), root0));
            bytes32[] memory newPeaks = new bytes32[](1);
            newPeaks[0] = root0;
            return (pos, firstRoot, newPeaks);
        }

        bytes32 computedRoot = computeRoot(peaks, bytes32(lastPos));
        require(computedRoot == lastRoot, "unexpected root");

        bytes32 hash = keccak256(abi.encode(pos, elem));
        bytes32[] memory appendPeaks = StatelessMmrHelpers.newArrWithElem(peaks, hash);
        (bytes32[] memory updatedPeaks, uint updatedPos) = appendRec(0, appendPeaks, pos);
        bytes32 newRoot = computeRoot(updatedPeaks, bytes32(updatedPos));
        return (updatedPos, newRoot, updatedPeaks);
    }

    function append(bytes32 elem, bytes32[] memory peaks, uint lastPos, bytes32 lastRoot) internal pure returns (uint, bytes32) {
        uint pos = lastPos + 1;
        if (lastPos == 0) {
            bytes32 root0 = keccak256(abi.encode(bytes32(uint(1)), elem));
            bytes32 firstRoot = keccak256(abi.encode(bytes32(uint(1)), root0));
            return (pos, firstRoot);
        }

        bytes32 computedRoot = computeRoot(peaks, bytes32(lastPos));
        require(computedRoot == lastRoot, "unexpected root");

        bytes32 hash = keccak256(abi.encode(pos, elem));
        bytes32[] memory appendPeaks = StatelessMmrHelpers.newArrWithElem(peaks, hash);
        (bytes32[] memory updatedPeaks, uint updatedPos) = appendRec(0, appendPeaks, pos);
        bytes32 newRoot = computeRoot(updatedPeaks, bytes32(updatedPos));
        return (updatedPos, newRoot);
    }

    function appendRec(uint h, bytes32[] memory peaks, uint lastPos) internal pure returns (bytes32[] memory, uint) {
        uint pos = lastPos;
        uint nextHeight = height(pos + 1);

        bool isHigher = h + 1 <= nextHeight;
        if (isHigher) {
            pos += 1;

            bytes32 rightHash = peaks[peaks.length - 1];
            bytes32 leftHash = peaks[peaks.length - 2];
            uint peaks_len = peaks.length - 2;

            bytes32 hash = keccak256(abi.encode(leftHash, rightHash));
            bytes32 parentHash = keccak256(abi.encodePacked(pos, hash));
            bytes32[] memory mergedPeaks = new bytes32[](peaks_len + 1);
            for (uint i = 0; i < peaks_len; i++) {
                mergedPeaks[i] = peaks[i];
            }
            mergedPeaks[peaks_len] = parentHash;
            return appendRec(h + 1, mergedPeaks, pos);
        }
        return (peaks, pos);
    }

    function computeRoot(bytes32[] memory peaks, bytes32 size) internal pure returns (bytes32) {
        bytes32 baggedPeaks = bagPeaks(peaks);
        return keccak256(abi.encode(size, baggedPeaks));
    }

    function bagPeaks(bytes32[] memory peaks) internal pure returns (bytes32) {
        require(peaks.length >= 1, "peaks must have at least one element");
        if (peaks.length == 1) {
            return peaks[0];
        }

        uint len = peaks.length;
        bytes32 root0 = keccak256(abi.encode(peaks[len - 2], peaks[len - 1]));
        bytes32[] memory reversedPeaks = new bytes32[](len - 2);
        for (uint i = 0; i < len - 2; i++) {
            reversedPeaks[i] = peaks[len - 3 - i];
        }

        bytes32 root = root0;
        for (uint i = 0; i < reversedPeaks.length; i++) {
            root = keccak256(abi.encode(reversedPeaks[i], root));
        }

        return root;
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
