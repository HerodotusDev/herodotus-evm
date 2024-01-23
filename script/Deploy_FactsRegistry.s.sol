// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {FactsRegistry} from "src/core/FactsRegistry.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_FactsRegistry is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address headersProcessor = vm.envAddress("HEADERS_PROCESSOR");

        vm.startBroadcast(deployerPrivateKey);

        FactsRegistry factsRegistry = new FactsRegistry(headersProcessor);

        console2.log("FactsRegistry deployed at address: %s", address(factsRegistry));

        vm.stopBroadcast();
    }
}
