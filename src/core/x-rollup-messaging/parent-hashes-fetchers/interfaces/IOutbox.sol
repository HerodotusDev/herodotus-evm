// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IOutbox {
    function roots(bytes32) external view returns (bytes32);// maps root hashes => L2 block hash
}