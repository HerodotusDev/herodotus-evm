// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {EVMHeaderRLP} from "../../src/lib/EVMHeaderRLP.sol";

contract EthereumHeaderLib_Test is Test {
    using Strings for uint256;

    uint256 private blockNumber = 7583800;
    bytes private rlp;

    constructor() {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = blockNumber.toString();

        bytes memory headerRlp = vm.ffi(inputs);
        rlp = headerRlp;
    }

    function test_decodeParentHash() public {
        bytes32 actualParentHash = EVMHeaderRLP.getParentHash(rlp);

        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_prop.js";
        inputs[2] = blockNumber.toString();
        inputs[3] = "parentHash";

        bytes memory expectedParentHashBytes = vm.ffi(inputs);
        bytes32 expectedParentHash = bytes32(expectedParentHashBytes);

        assertEq(actualParentHash, expectedParentHash);
    }

    function test_decodeStateRoot() public {
        bytes32 actualStateRoot = EVMHeaderRLP.getStateRoot(rlp);

        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_prop.js";
        inputs[2] = blockNumber.toString();
        inputs[3] = "stateRoot";

        bytes memory expectedStateRootBytes = vm.ffi(inputs);
        bytes32 expectedStateRoot = bytes32(expectedStateRootBytes);

        assertEq(actualStateRoot, expectedStateRoot);
    }

    function test_decodeTransactionsRoot() public {
        bytes32 actualTransactionsRoot = EVMHeaderRLP.getTransactionsRoot(rlp);

        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_prop.js";
        inputs[2] = blockNumber.toString();
        inputs[3] = "transactionsRoot";

        bytes memory expectedTransactionsRootBytes = vm.ffi(inputs);
        bytes32 expectedTransactionsRoot = bytes32(expectedTransactionsRootBytes);

        assertEq(actualTransactionsRoot, expectedTransactionsRoot);
    }

    function test_decodeReceiptsRoot() public {
        bytes32 actualReceiptsRoot = EVMHeaderRLP.getReceiptsRoot(rlp);

        string[] memory inputs = new string[](4);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_prop.js";
        inputs[2] = blockNumber.toString();
        inputs[3] = "receiptsRoot";

        bytes memory expectedReceiptsRootBytes = vm.ffi(inputs);
        bytes32 expectedReceiptsRoot = bytes32(expectedReceiptsRootBytes);

        assertEq(actualReceiptsRoot, expectedReceiptsRoot);
    }
}
