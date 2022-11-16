// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {console} from "../helpers/console.sol";

import {CheatCodes} from "../utils/CheatCodes.sol";
import {EthereumHeader} from "../../src/lib/EthereumHeader.sol";

contract EthereumHeaderLib_Test is Test {
    function test_decodeParentHash() public {
        string[] memory inputs = new string[](2);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";

        bytes memory res = vm.ffi(inputs);
        console.logBytes(res);
        // string memory output = abi.decode(res, (string));
    }
}
