// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {StatelessMmr} from "../../src/lib/mmr/StatelessMmr.sol";

contract StatelessMmrLib_Test is Test {
    bytes32[] peaks;

    function setUp() public {
        delete peaks; // Reset the storage array
        assertEq(peaks.length, 0);
    }

    function printArr(bytes32[] memory arr) internal view {
        for (uint i = 0; i < arr.length; i++) {
            console.log("arr[%s] ->", i);
            console.logBytes32(arr[i]);
        }
    }

    function comparePeaks(bytes32[] memory peaks1, bytes32[] memory peaks2) internal pure returns (bool) {
        if (peaks1.length != peaks2.length) {
            return false;
        }
        for (uint i = 0; i < peaks1.length; i++) {
            if (peaks1[i] != peaks2[i]) {
                return false;
            }
        }
        return true;
    }

    function testAppendInitial() public returns (uint, bytes32, bytes32[] memory) {
        bytes32 node1 = keccak256(abi.encodePacked(uint(1), uint(1)));
        peaks.push(node1);

        (uint newPos, bytes32 newRoot, bytes32[] memory newPeaks) = StatelessMmr.append(1, peaks, 0, bytes32(0));
        assertEq(newPos, 1);

        bytes32 expectedRoot = keccak256(abi.encodePacked(uint(1), node1));
        assertEq(newRoot, expectedRoot);
        bytes32 expectedRootMethod2 = StatelessMmr.computeRoot(peaks, newPos);
        assertEq(newRoot, expectedRootMethod2);
        return (newPos, newRoot, newPeaks);
    }

    function testAppendOne() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, ) = testAppendInitial();
        (uint newPos, bytes32 newRoot, bytes32[] memory newPeaks) = StatelessMmr.append(2, peaks, lastPos, lastRoot);
        assertEq(newPos, 3);

        bytes32 node2 = keccak256(abi.encodePacked(uint(2), uint(2)));
        peaks.push(node2);

        bytes32 node3_1 = keccak256(abi.encodePacked(peaks[0], peaks[1]));
        bytes32 node3 = keccak256(abi.encodePacked(uint(3), node3_1));
        peaks.push(node3);

        bytes32 expectedRoot = StatelessMmr.computeRoot(peaks, newPos);
        assertEq(newRoot, expectedRoot);
        assertTrue(comparePeaks(peaks, newPeaks));
        return (newPos, newRoot, newPeaks);
    }

    function testAppendTwo() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, ) = testAppendOne();
        (uint newPos, bytes32 newRoot, bytes32[] memory newPeaks) = StatelessMmr.append(4, peaks, lastPos, lastRoot);
        assertEq(newPos, 4);

        bytes32 expectedRoot = StatelessMmr.computeRoot(newPeaks, newPos);
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, newPeaks);
    }

    function testAppendThree() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendTwo();
        (uint newPos, bytes32 newRoot, bytes32[] memory newPeaks) = StatelessMmr.append(5, lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 7);

        bytes32 expectedRoot = StatelessMmr.computeRoot(newPeaks, newPos);
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, newPeaks);
    }

    function testAppendFour() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendThree();
        (uint newPos, bytes32 newRoot, bytes32[] memory newPeaks) = StatelessMmr.append(8, lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 8);

        bytes32 expectedRoot = StatelessMmr.computeRoot(newPeaks, newPos);
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, newPeaks);
    }
}
