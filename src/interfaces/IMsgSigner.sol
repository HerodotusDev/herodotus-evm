// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMsgSigner {
    function verify(bytes32 hash, bytes calldata sig) external view;

    function signingKey() external view returns (bytes32);
}
