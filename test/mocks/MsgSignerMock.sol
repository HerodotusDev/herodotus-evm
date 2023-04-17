// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IMsgSigner} from "../../src/interfaces/IMsgSigner.sol";

contract MsgSignerMock is IMsgSigner {
    function verify(bytes32 hash, bytes calldata sig) external view {}

    function signingKey() external pure returns (bytes32) {
        return bytes32(0);
    }
}
