// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {OpStackParentHashesFetcher} from "src/core/x-rollup-messaging/parent-hashes-fetchers/OpStackParentHashesFetcher.sol";
import {IL2OutputOracle} from "src/core/x-rollup-messaging/parent-hashes-fetchers/interfaces/IL2OutputOracle.sol";

import {console2} from "forge-std/console2.sol";

contract Deploy_OpStackParentHashesFetcher is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address l2OutputOracle = vm.envAddress("L2_OUTPUT_ORACLE");

        OpStackParentHashesFetcher opStackParentHashesFetcher = new OpStackParentHashesFetcher(IL2OutputOracle(l2OutputOracle), 11155111);

        console2.log("OpStackParentHashesFetcher address: %s", address(opStackParentHashesFetcher));

        vm.stopBroadcast();
    }
}
