// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library EthereumHeader {
    function decodeParentHash(bytes memory header) internal pure returns (bytes32) {}

    function decodeStateRoot(bytes memory header) internal pure returns (bytes32) {}

    function decodeTransactionsRoot(bytes memory header) internal pure returns (bytes32) {}

    function decodeReceiptsRoot(bytes memory header) internal pure returns (bytes32) {}
}
