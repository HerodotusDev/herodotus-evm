// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {console} from "../helpers/console.sol";

import {CheatCodes} from "../utils/CheatCodes.sol";
import {EthereumHeader} from "../../src/lib/EthereumHeader.sol";

contract EthereumHeaderLib_Test is Test {
    function test_decodeParentHash() public {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "-n";
        inputs[2] = "./helpers/fetch_header_rlp.js";
        // inputs[1] = "-n";
        // inputs[
        //     2
        // ] = "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002676d000000000000000000000000000000000000000000000000000000000000";

        bytes memory res = vm.ffi(inputs);
        console.logBytes(res);
        // string memory output = abi.decode(res, (string));
    }
}
