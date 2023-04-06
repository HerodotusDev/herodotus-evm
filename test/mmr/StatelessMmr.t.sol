// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {StatelessMmr} from "../../src/lib/mmr/StatelessMmr.sol";
import {StatelessMmrHelpers} from "../../src/lib/mmr/StatelessMmrHelpers.sol";

contract StatelessMmrLib_Test is Test {
    function testInvalidBagPeaks() public {
        // Test bagging with an invalid size (empty peaks array)
        vm.expectRevert("peaks must have at least one element");
        StatelessMmr.bagPeaks(new bytes32[](0));
    }

    function testBagPeaks() public {
        bytes32[] memory peaks = new bytes32[](0);

        // Test bagging with one element
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, bytes32(uint(1)));
        bytes32 baggedPeaks = StatelessMmr.bagPeaks(peaks);
        assertEq(baggedPeaks, peaks[0]);

        // Test bagging with two elements
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, bytes32(uint(2)));
        baggedPeaks = StatelessMmr.bagPeaks(peaks);
        bytes32 expectedBags = keccak256(abi.encodePacked(peaks[1], peaks[0]));
        assertEq(baggedPeaks, expectedBags);

        // Test bagging with three elements
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, bytes32(uint(3)));
        baggedPeaks = StatelessMmr.bagPeaks(peaks);
        expectedBags = keccak256(abi.encodePacked(keccak256(abi.encodePacked(peaks[2], peaks[1])), peaks[0]));
        assertEq(baggedPeaks, expectedBags);
    }

    function testComputeRoot() public {
        bytes32[] memory peaks = new bytes32[](3);
        for (uint i = 0; i < 3; ++i) {
            peaks[i] = bytes32(uint(i));
        }
        assertEq(peaks.length, 3);
        bytes32 baggedPeaks = StatelessMmr.bagPeaks(peaks);
        uint pos = 7; // Expected pos after 3 appended elements
        bytes32 expectedRoot = keccak256(abi.encodePacked(pos, baggedPeaks));
        bytes32 root = StatelessMmr.computeRoot(peaks, pos);
        assertEq(root, expectedRoot);
    }

    function testAppendInitial() public returns (uint, bytes32, bytes32) {
        bytes32[] memory peaks = new bytes32[](0);
        bytes32 node1 = keccak256(abi.encodePacked(uint(1), uint(1)));

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(1, peaks, 0, bytes32(0));
        assertEq(newPos, 1);

        bytes32 expectedRoot = keccak256(abi.encodePacked(uint(1), node1));
        assertEq(newRoot, expectedRoot);
        peaks = new bytes32[](1);
        peaks[0] = node1;
        bytes32 expectedRootMethod2 = StatelessMmr.computeRoot(peaks, newPos);
        assertEq(newRoot, expectedRootMethod2);

        return (newPos, newRoot, node1);
    }

    function testAppendOne() public returns (uint, bytes32, bytes32) {
        (uint lastPos, bytes32 lastRoot, bytes32 node1) = testAppendInitial();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node1;

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(2, peaks, lastPos, lastRoot);
        assertEq(newPos, 3);

        bytes32 node2 = keccak256(abi.encodePacked(uint(2), uint(2)));
        bytes32 node3_1 = keccak256(abi.encodePacked(node1, node2));
        bytes32 node3 = keccak256(abi.encodePacked(uint(3), node3_1));
        bytes32 expectedRoot = keccak256(abi.encodePacked(uint(3), node3));
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, node3);
    }

    function testAppendTwo() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32 node3) = testAppendOne();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node3;

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(4, peaks, lastPos, lastRoot);
        assertEq(newPos, 4);

        bytes32 node4 = keccak256(abi.encodePacked(uint(4), uint(4)));
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, node4);
        bytes32 expectedRoot = StatelessMmr.computeRoot(peaks, newPos);
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, peaks);
    }

    function testAppendThree() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendTwo();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(5, lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 7);

        bytes32 node5 = keccak256(abi.encodePacked(uint(5), uint(5)));
        bytes32 node6_1 = keccak256(abi.encodePacked(lastPeaks[1], node5));
        bytes32 node6 = keccak256(abi.encodePacked(uint(6), node6_1));
        bytes32 node7_1 = keccak256(abi.encodePacked(lastPeaks[0], node6));
        bytes32 node7 = keccak256(abi.encodePacked(uint(7), node7_1));

        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node7;
        bytes32 expectedRoot = StatelessMmr.computeRoot(peaks, newPos);
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, peaks);
    }

    function testAppendFour() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendThree();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(8, lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 8);

        bytes32 node8 = keccak256(abi.encodePacked(uint(8), uint(8)));
        bytes32[] memory peaks = StatelessMmrHelpers.newArrWithElem(lastPeaks, node8);
        bytes32 expectedRoot = StatelessMmr.computeRoot(peaks, newPos);
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, peaks);
    }

    function testVerifyProofOneLeaf() public {
        bytes32[] memory peaks = new bytes32[](0);
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(1, peaks, 0, bytes32(0));
        assertEq(newPos, 1);

        bytes32 node1 = keccak256(abi.encodePacked(uint(1), uint(1)));
        // peaks.push(node1);
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, node1);

        StatelessMmr.verifyProof(1, 1, new bytes32[](0), peaks, newPos, newRoot);
    }

    function testVerifyProofTwoLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32 node1) = testAppendInitial();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node1;
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(2, peaks, lastPos, lastRoot);
        assertEq(newPos, 3);

        bytes32 node2 = keccak256(abi.encodePacked(uint(2), uint(2)));
        bytes32 node3_1 = keccak256(abi.encodePacked(node1, node2));
        bytes32 node3 = keccak256(abi.encodePacked(uint(3), node3_1));
        peaks = new bytes32[](1);
        peaks[0] = node3;

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = node1;

        StatelessMmr.verifyProof(2, 2, proof, peaks, newPos, newRoot);
    }

    function testVerifyProofThreeLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32 node3) = testAppendOne();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node3;

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(4, peaks, lastPos, lastRoot);
        assertEq(newPos, 4);

        bytes32 node4 = keccak256(abi.encodePacked(uint(4), uint(4)));
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, node4);

        StatelessMmr.verifyProof(4, 4, new bytes32[](0), peaks, newPos, newRoot);
    }

    function testVerifyProofFourLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendTwo();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(5, lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 7);

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = lastPeaks[1];
        proof[1] = lastPeaks[0];

        bytes32 node5 = keccak256(abi.encodePacked(uint(5), uint(5)));
        bytes32 node6_1 = keccak256(abi.encodePacked(lastPeaks[1], node5));
        bytes32 node6 = keccak256(abi.encodePacked(uint(6), node6_1));
        bytes32 node7_1 = keccak256(abi.encodePacked(lastPeaks[0], node6));
        bytes32 node7 = keccak256(abi.encodePacked(uint(7), node7_1));
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node7;

        StatelessMmr.verifyProof(5, 5, proof, peaks, newPos, newRoot);
    }

    function testVerifyProofFiveLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendThree();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(8, lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 8);

        bytes32 node8 = keccak256(abi.encodePacked(uint(8), uint(8)));
        bytes32[] memory peaks = StatelessMmrHelpers.newArrWithElem(lastPeaks, node8);

        StatelessMmr.verifyProof(8, 8, new bytes32[](0), peaks, newPos, newRoot);
    }
}
