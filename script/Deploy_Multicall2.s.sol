// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {Multicall2} from "../src/core/external/Multicall2.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_Multicall2 is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Multicall2 multicall2 = new Multicall2();

        console2.log("Multicall2 deployed at address: %s", address(multicall2));

        vm.stopBroadcast();
    }
}
