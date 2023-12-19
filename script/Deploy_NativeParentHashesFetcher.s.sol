// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {NativeParentHashesFetcher} from "../src/core/x-rollup-messaging/parent-hashes-fetchers/Native.sol";

import {console2} from "forge-std/console2.sol";

contract Deploy_NativeParentHashesFetcher is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        NativeParentHashesFetcher nativeParentHashesFetcher = new NativeParentHashesFetcher();

        console2.log("NativeParentHashesFetcher address: %s", address(nativeParentHashesFetcher));

        vm.stopBroadcast();
    }
}
