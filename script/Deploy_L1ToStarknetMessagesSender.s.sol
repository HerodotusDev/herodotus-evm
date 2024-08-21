// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1ToStarknetMessagesSender} from "../src/core/x-rollup-messaging/outbox/L1ToStarknetMessagesSender.sol";
import {IStarknetCore} from "../src/core/x-rollup-messaging/interfaces/IStarknetCore.sol";
import {IParentHashFetcher} from "../src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";
import {NativeParentHashesFetcher} from "src/core/x-rollup-messaging/parent-hashes-fetchers/NativeParentHashesFetcher.sol";

contract Deploy_L1ToStarknetMessagesSender is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("L1_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NativeParentHashesFetcher parentHashFetcher = new NativeParentHashesFetcher();

        L1ToStarknetMessagesSender l1MessagesSender = new L1ToStarknetMessagesSender(
            IStarknetCore(vm.envAddress("STARKNET_CORE_ADDRESS")),
            vm.envUint("L2_RECIPIENT_ADDRESS"),
            vm.envAddress("L1_MAINNET_AGGREGATORS_FACTORY"),
            IParentHashFetcher(address(parentHashFetcher))
        );

        console.log("L1MessagesSender address: %s", address(l1MessagesSender));
        console.log("NativeParentHashesFetcher address: %s", address(parentHashFetcher));

        vm.stopBroadcast();
    }
}
