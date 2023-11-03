// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {FactsRegistry} from "../src/core/FactsRegistry.sol";


contract Deploy_FactsRegistry is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address headersProcessor = vm.envAddress("HEADERS_PROCESSOR");

        vm.startBroadcast(deployerPrivateKey);

        FactsRegistry factsRegistry = new FactsRegistry(headersProcessor);
        vm.stopBroadcast();
    }
}