// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {L1ToStarknetMessagesSender} from "../src/core/x-rollup-messaging/outbox/L1ToStarknetMessagesSender.sol";
import {IStarknetCore} from "../src/core/x-rollup-messaging/interfaces/IStarknetCore.sol";
import {IParentHashFetcher} from "../src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";

contract Deploy_L1ToStarknetMessagesSender is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        L1ToStarknetMessagesSender l1MessagesSender = new L1ToStarknetMessagesSender(
            IStarknetCore(vm.envAddress("STARKNET_CORE_ADDRESS")),
            vm.envUint("L2_RECIPIENT_ADDRESS"),
            vm.envAddress("AGGREGATORS_FACTORY_ADDRESS"),
            IParentHashFetcher(vm.envAddress("PARENT_HASH_FETCHER"))
        );

        console.log("L1MessagesSender address: %s", address(l1MessagesSender));

        vm.stopBroadcast();
    }
}
