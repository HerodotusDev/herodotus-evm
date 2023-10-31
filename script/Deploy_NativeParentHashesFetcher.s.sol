// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {NativeParentHashesFetcher} from "../src/core/x-rollup-messaging/parent-hashes-fetchers/Native.sol";


contract Deploy_NativeParentHashesFetcher is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        NativeParentHashesFetcher nativeParentHashesFetcher = new NativeParentHashesFetcher();
        vm.stopBroadcast();
    }
}