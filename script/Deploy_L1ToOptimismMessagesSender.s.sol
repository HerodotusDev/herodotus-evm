// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {L1ToOptimismMessagesSender} from "../src/core/x-rollup-messaging/L1ToOptimismMessagesSender.sol";
import {IOptimismCrossDomainMessenger} from
    "../src/core/x-rollup-messaging/interfaces/IOptimismCrossDomainMessenger.sol";
import {IParentHashFetcher} from "../src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";
import {ISharpProofsAggregatorsFactory} from "../src/core/interfaces/ISharpProofsAggregatorsFactory.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_L1ToOptimismMessagesSender is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address proofsAggregatorsFactory = vm.envAddress("PROOFS_AGGREGATORS_FACTORY");
        address parentHashFetcher = vm.envAddress("PARENT_HASH_FETCHER");
        address l2Target = vm.envAddress("L2_TARGET");
        address optimismMessenger = vm.envAddress("OPTIMISM_CROSS_DOMAIN_MESSENGER");

        vm.startBroadcast(deployerPrivateKey);

        L1ToOptimismMessagesSender l1ToOptimismMessagesSender = new L1ToOptimismMessagesSender(
            ISharpProofsAggregatorsFactory(proofsAggregatorsFactory),
            IParentHashFetcher(parentHashFetcher),
            l2Target,
            IOptimismCrossDomainMessenger(optimismMessenger)
        );

        console2.log("L1ToOptimismMessagesSender address: %s", address(l1ToOptimismMessagesSender));

        vm.stopBroadcast();
    }
}
