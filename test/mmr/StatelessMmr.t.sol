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
        bytes32 expectedBags = keccak256(abi.encode(peaks[0], peaks[1]));
        assertEq(baggedPeaks, expectedBags);

        // Test bagging with three elements
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, bytes32(uint(3)));
        bytes32 root0 = keccak256(abi.encode(peaks[1], peaks[2]));
        bytes32 root = keccak256(abi.encode(peaks[0], root0));
        baggedPeaks = StatelessMmr.bagPeaks(peaks);
        assertEq(baggedPeaks, root);
    }

    function testComputeRootEmpty() public {
        bytes32[] memory peaks = new bytes32[](0);
        vm.expectRevert("peaks must have at least one element");
        bytes32 root = StatelessMmr.computeRoot(peaks, 0);
        assertEq(root, bytes32(0));
    }

    function testComputeRoot1() public {
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = keccak256(abi.encode(bytes32(uint(1)), bytes32(uint(1))));

        bytes32 root = StatelessMmr.computeRoot(peaks, bytes32(uint(1)));
        assertEq(root, keccak256(abi.encode(bytes32(uint(1)), peaks[0])));
    }

    function testComputeRoot2() public {
        bytes32[] memory peaks = new bytes32[](2);
        peaks[0] = keccak256(abi.encode(bytes32(uint(1)), bytes32(uint(843984))));
        peaks[1] = keccak256(abi.encode(bytes32(uint(7)), bytes32(uint(38474983))));

        bytes32 root = StatelessMmr.computeRoot(peaks, bytes32(uint(7)));
        bytes32 expectedRoot = keccak256(abi.encode(bytes32(uint(7)), keccak256(abi.encode(peaks[0], peaks[1]))));
        assertEq(root, expectedRoot);
    }

    function testComputeRoot3() public {
        bytes32[] memory peaks = new bytes32[](3);
        peaks[0] = keccak256(abi.encode(bytes32(uint(245)), bytes32(uint(2480))));
        peaks[1] = keccak256(abi.encode(bytes32(uint(2340)), bytes32(uint(23428))));
        peaks[2] = keccak256(abi.encode(bytes32(uint(923048)), bytes32(uint(283409))));

        bytes32 root = StatelessMmr.computeRoot(peaks, bytes32(uint(923048)));
        bytes32 expectedRoot = keccak256(abi.encode(bytes32(uint(923048)), keccak256(abi.encode(peaks[0], keccak256(abi.encode(peaks[1], peaks[2]))))));
        assertEq(root, expectedRoot);
    }

    function testComputeRoot() public {
        bytes32[] memory peaks = new bytes32[](3);
        for (uint i = 0; i < 3; ++i) {
            peaks[i] = bytes32(uint(i));
        }
        assertEq(peaks.length, 3);
        bytes32 baggedPeaks = StatelessMmr.bagPeaks(peaks);
        uint pos = 7; // Expected pos after 3 appended elements
        bytes32 expectedRoot = keccak256(abi.encode(pos, baggedPeaks));
        bytes32 root = StatelessMmr.computeRoot(peaks, bytes32(pos));
        assertEq(root, expectedRoot);
    }

    function testAppendInitial() public returns (uint, bytes32, bytes32) {
        bytes32[] memory peaks = new bytes32[](0);
        bytes32 node1 = keccak256(abi.encode(bytes32(uint(1)), bytes32(uint(1))));

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(1)), peaks, 0, bytes32(0));
        assertEq(newPos, 1);

        bytes32 expectedRoot = keccak256(abi.encode(bytes32(uint(1)), node1));
        assertEq(newRoot, expectedRoot);

        peaks = new bytes32[](1);
        peaks[0] = node1;
        bytes32 expectedRootMethod2 = StatelessMmr.computeRoot(peaks, bytes32(newPos));
        assertEq(newRoot, expectedRootMethod2);

        return (newPos, newRoot, node1);
    }

    function testAppendOne() public returns (uint, bytes32, bytes32) {
        (uint lastPos, bytes32 lastRoot, bytes32 node1) = testAppendInitial();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node1;

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(2)), peaks, lastPos, lastRoot);
        assertEq(newPos, 3);

        bytes32 node2 = keccak256(abi.encode(bytes32(uint(2)), bytes32(uint(2))));
        bytes32 node3_1 = keccak256(abi.encode(node1, node2));
        bytes32 node3 = keccak256(abi.encode(bytes32(uint(3)), node3_1));
        bytes32 expectedRoot = keccak256(abi.encode(bytes32(uint(3)), node3));
        assertEq(newRoot, expectedRoot);
        return (newPos, newRoot, node3);
    }

    function testAppendTwo() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32 node3) = testAppendOne();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node3;

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(4)), peaks, lastPos, lastRoot);
        assertEq(newPos, 4);

        bytes32 node4 = keccak256(abi.encode(bytes32(uint(4)), bytes32(uint(4))));
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, node4);
        bytes32 expectedRoot = StatelessMmr.computeRoot(peaks, bytes32(newPos));
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, peaks);
    }

    function testAppendThree() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendTwo();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(5)), lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 7);

        bytes32 node5 = keccak256(abi.encode(bytes32(uint(5)), bytes32(uint(5))));
        bytes32 node6_1 = keccak256(abi.encode(lastPeaks[1], node5));
        bytes32 node6 = keccak256(abi.encode(bytes32(uint(6)), node6_1));
        bytes32 node7_1 = keccak256(abi.encode(lastPeaks[0], node6));
        bytes32 node7 = keccak256(abi.encode(bytes32(uint(7)), node7_1));

        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node7;
        bytes32 expectedRoot = StatelessMmr.computeRoot(peaks, bytes32(newPos));
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, peaks);
    }

    function testAppendFour() public returns (uint, bytes32, bytes32[] memory) {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendThree();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(8)), lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 8);

        bytes32 node8 = keccak256(abi.encode(bytes32(uint(8)), bytes32(uint(8))));
        bytes32[] memory peaks = StatelessMmrHelpers.newArrWithElem(lastPeaks, node8);
        bytes32 expectedRoot = StatelessMmr.computeRoot(peaks, bytes32(newPos));
        assertEq(newRoot, expectedRoot);

        return (newPos, newRoot, peaks);
    }

    function testMultiAppendSingleElement() public {
        bytes32[] memory elems = new bytes32[](1);
        elems[0] = bytes32(uint(1));
        bytes32[] memory peaks = new bytes32[](0);

        (uint newPos, ) = StatelessMmr.multiAppend(elems, peaks, 0, bytes32(0));
        assertEq(newPos, 1);
    }

    function testMultiAppendTwoElements() public {
        bytes32[] memory elems = new bytes32[](2);
        elems[0] = bytes32(uint(1));
        elems[1] = bytes32(uint(2));

        (uint newPos, ) = StatelessMmr.multiAppend(elems, new bytes32[](0), 0, bytes32(0));
        assertEq(newPos, 3);
    }

    function testMultiAppendThreeElements() public {
        bytes32[] memory elems = new bytes32[](3);
        elems[0] = bytes32(uint(1));
        elems[1] = bytes32(uint(2));
        elems[2] = bytes32(uint(3));

        (uint newPos, ) = StatelessMmr.multiAppend(elems, new bytes32[](0), 0, bytes32(0));
        assertEq(newPos, 4);
    }

    function testMultiAppendFourElements() public {
        bytes32[] memory elems = new bytes32[](4);
        elems[0] = bytes32(uint(1));
        elems[1] = bytes32(uint(2));
        elems[2] = bytes32(uint(3));
        elems[3] = bytes32(uint(4));

        (uint newPos, ) = StatelessMmr.multiAppend(elems, new bytes32[](0), 0, bytes32(0));
        assertEq(newPos, 7);
    }

    function testMultiAppendiveElements() public {
        bytes32[] memory elems = new bytes32[](5);
        elems[0] = bytes32(uint(1));
        elems[1] = bytes32(uint(2));
        elems[2] = bytes32(uint(3));
        elems[3] = bytes32(uint(4));
        elems[4] = bytes32(uint(5));

        (uint newPos, ) = StatelessMmr.multiAppend(elems, new bytes32[](0), 0, bytes32(0));
        assertEq(newPos, 8);
    }

    function testVerifyProofOneLeaf() public {
        bytes32[] memory peaks = new bytes32[](0);
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(1)), peaks, 0, bytes32(0));
        assertEq(newPos, 1);

        bytes32 node1 = keccak256(abi.encode(bytes32(uint(1)), bytes32(uint(1))));
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, node1);

        StatelessMmr.verifyProof(1, bytes32(uint(1)), new bytes32[](0), peaks, newPos, newRoot);
    }

    function testVerifyProofTwoLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32 node1) = testAppendInitial();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node1;
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(2)), peaks, lastPos, lastRoot);
        assertEq(newPos, 3);

        bytes32 node2 = keccak256(abi.encode(bytes32(uint(2)), bytes32(uint(2))));
        bytes32 node3_1 = keccak256(abi.encode(node1, node2));
        bytes32 node3 = keccak256(abi.encode(bytes32(uint(3)), node3_1));
        peaks = new bytes32[](1);
        peaks[0] = node3;

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = node1;

        StatelessMmr.verifyProof(2, bytes32(uint(2)), proof, peaks, newPos, newRoot);
    }

    function testVerifyProofThreeLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32 node3) = testAppendOne();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node3;

        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(4)), peaks, lastPos, lastRoot);
        assertEq(newPos, 4);

        bytes32 node4 = keccak256(abi.encode(bytes32(uint(4)), bytes32(uint(4))));
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, node4);

        StatelessMmr.verifyProof(4, bytes32(uint(4)), new bytes32[](0), peaks, newPos, newRoot);
    }

    function testVerifyProofFourLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendTwo();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(5)), lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 7);

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = lastPeaks[1];
        proof[1] = lastPeaks[0];

        bytes32 node5 = keccak256(abi.encode(bytes32(uint(5)), bytes32(uint(5))));
        bytes32 node6_1 = keccak256(abi.encode(lastPeaks[1], node5));
        bytes32 node6 = keccak256(abi.encode(bytes32(uint(6)), node6_1));
        bytes32 node7_1 = keccak256(abi.encode(lastPeaks[0], node6));
        bytes32 node7 = keccak256(abi.encode(bytes32(uint(7)), node7_1));
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node7;

        StatelessMmr.verifyProof(5, bytes32(uint(5)), proof, peaks, newPos, newRoot);
    }

    function testVerifyProofFiveLeaves() public {
        (uint lastPos, bytes32 lastRoot, bytes32[] memory lastPeaks) = testAppendThree();
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(8)), lastPeaks, lastPos, lastRoot);
        assertEq(newPos, 8);

        bytes32 node8 = keccak256(abi.encode(bytes32(uint(8)), bytes32(uint(8))));
        bytes32[] memory peaks = StatelessMmrHelpers.newArrWithElem(lastPeaks, node8);

        StatelessMmr.verifyProof(8, bytes32(uint(8)), new bytes32[](0), peaks, newPos, newRoot);
    }

    function testVerifyProofInvalidIndex() public {
        bytes32[] memory peaks = new bytes32[](0);
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(1)), peaks, 0, bytes32(0));
        assertEq(newPos, 1);

        bytes32 node1 = keccak256(abi.encode(bytes32(uint(1)), bytes32(uint(1))));
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, node1);

        vm.expectRevert();
        StatelessMmr.verifyProof(2, bytes32(uint(2)), new bytes32[](0), peaks, newPos, newRoot);
    }

    function testVerifyProofInvalidPeaks() public {
        bytes32[] memory peaks = new bytes32[](0);
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(1)), peaks, 0, bytes32(0));
        assertEq(newPos, 1);

        bytes32 invalidNode1 = keccak256(abi.encode(bytes32(uint(1)), bytes32(uint(42))));
        peaks = StatelessMmrHelpers.newArrWithElem(peaks, invalidNode1);

        vm.expectRevert();
        StatelessMmr.verifyProof(1, bytes32(uint(1)), new bytes32[](0), peaks, newPos, newRoot);
    }

    function testVerifyProofInvalidProof() public {
        (uint lastPos, bytes32 lastRoot, bytes32 node1) = testAppendInitial();
        bytes32[] memory peaks = new bytes32[](1);
        peaks[0] = node1;
        (uint newPos, bytes32 newRoot) = StatelessMmr.append(bytes32(uint(2)), peaks, lastPos, lastRoot);
        assertEq(newPos, 3);

        bytes32 node2 = keccak256(abi.encode(bytes32(uint(2)), bytes32(uint(2))));
        bytes32 node3_1 = keccak256(abi.encode(node1, node2));
        bytes32 node3 = keccak256(abi.encode(bytes32(uint(3)), node3_1));
        peaks = new bytes32[](1);
        peaks[0] = node3;

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = node3; // Invalid on purpose (should be node1 instead)

        vm.expectRevert();
        StatelessMmr.verifyProof(2, bytes32(uint(2)), proof, peaks, newPos, newRoot);
    }

    function testHeightRevert() public {
        vm.expectRevert("index must be at least 1");
        StatelessMmr.height(0);
    }

    function testHeight() public {
        assertEq(StatelessMmr.height(1), 0);
        assertEq(StatelessMmr.height(2), 0);
        assertEq(StatelessMmr.height(3), 1);
        assertEq(StatelessMmr.height(7), 2);
        assertEq(StatelessMmr.height(8), 0);
        assertEq(StatelessMmr.height(46), 3);
        assertEq(StatelessMmr.height(49), 1);
    }

    function testMmrLibInteroperabilityAppends() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/off_chain_mmr.js";
        inputs[2] = "100"; // Number of append to perform
        bytes memory output = vm.ffi(inputs);
        bytes32[] memory rootHashes = abi.decode(output, (bytes32[]));

        assertEq(rootHashes.length, 100);

        uint pos = 0;
        bytes32 root = bytes32(0);
        bytes32[] memory updatedPeaks = new bytes32[](0);

        // @notice make sure it matches the number of appends performed in the off-chain script
        for (uint i = 0; i < 100; ++i) {
            (pos, root, updatedPeaks) = StatelessMmr.appendWithPeaksRetrieval(bytes32(uint(i + 1)), updatedPeaks, pos, root);
            assertEq(root, rootHashes[i]);
        }
    }

    function createStringArray(uint numStrings, bytes memory input, string memory delimiter) internal pure returns (string[] memory) {
        uint[] memory stringLengths = new uint[](numStrings);
        uint curLen = 0;
        uint strIdx = 0;
        for (uint256 i = 0; i < bytes(input).length; i++) {
            if (bytes(input)[i] == bytes(delimiter)[0]) {
                stringLengths[strIdx++] = curLen;
                curLen = 0;
            } else {
                ++curLen;
            }
        }
        stringLengths[strIdx] = curLen;

        string[] memory stringArray = new string[](numStrings);
        bytes memory substring = new bytes(stringLengths[0]);
        uint stringArrayIndex = 0;
        uint j = 0;
        for (uint256 i = 0; i < bytes(input).length; i++) {
            if ((bytes(input)[i] == bytes(delimiter)[0])) {
                stringArray[stringArrayIndex++] = string(substring);
                substring = new bytes(stringLengths[stringArrayIndex]);
                j = 0;
            } else {
                substring[j++] = bytes(input)[i];
            }
        }
        stringArray[stringArrayIndex] = string(substring);
        return stringArray;
    }

    function hexStringToBytesMemory(string memory hexString) internal pure returns (bytes memory) {
        bytes memory result = new bytes((bytes(hexString).length) / 2);

        for (uint i = 0; i < bytes(hexString).length; i += 2) {
            uint8 firstNibble = charToNibble(uint8(bytes(hexString)[i]));
            uint8 secondNibble = charToNibble(uint8(bytes(hexString)[i + 1]));
            result[i / 2] = bytes1((firstNibble << 4) | secondNibble);
        }

        return result;
    }

    function charToNibble(uint8 char) internal pure returns (uint8) {
        if (char >= uint8(bytes1("0")) && char <= uint8(bytes1("9"))) {
            return char - uint8(bytes1("0"));
        }
        if (char >= uint8(bytes1("a")) && char <= uint8(bytes1("f"))) {
            return 10 + (char - uint8(bytes1("a")));
        }
        if (char >= uint8(bytes1("A")) && char <= uint8(bytes1("F"))) {
            return 10 + (char - uint8(bytes1("A")));
        }
        revert("Invalid hex character");
    }

    function testMmrLibInteroperabilityProofsDebug() public {
        // Compile-time
        bytes
            memory s = hex"edb38a93e6e2e82dbb40826a878df1d817a37ef13fcaa25248649a90fa47497b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f";

        // Run-time
        bytes memory s2 = hexStringToBytesMemory(
            "edb38a93e6e2e82dbb40826a878df1d817a37ef13fcaa25248649a90fa47497b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f"
        );

        assertEq(s, s2);
    }

    function substr(string memory str, uint startIndex) internal pure returns (string memory) {
        uint endIndex = bytes(str).length;
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function testMmrLibInteroperabilityProofs() public {
        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/off_chain_mmr.js";
        inputs[2] = "100"; // Number of append to perform
        inputs[3] = "true"; // Ask node.js to generate proofs
        bytes memory output = vm.ffi(inputs);

        string[] memory outputStrings = createStringArray(100, output, ";");
        assertEq(outputStrings.length, 100);

        for (uint i = 0; i < outputStrings.length; ++i) {
            string memory s = outputStrings[i];
            (uint index, bytes32 value, bytes32[] memory proof, bytes32[] memory peaks, uint pos, bytes32 root) = abi.decode(
                hexStringToBytesMemory(substr(s, 2)),
                (uint, bytes32, bytes32[], bytes32[], uint, bytes32)
            );

            // Verify proof
            StatelessMmr.verifyProof(index, value, proof, peaks, pos, root);
        }
    }
}
