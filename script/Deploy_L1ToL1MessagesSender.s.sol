// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {L1ToL1MessagesSender} from "../src/core/x-rollup-messaging/L1ToL1MessagesSender.sol";
import {IParentHashFetcher} from "../src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";
import {ISharpProofsAggregatorsFactory} from "../src/core/interfaces/ISharpProofsAggregatorsFactory.sol";


contract Deploy_L1ToL1MessagesSender is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address proofsAggregatorsFactory = vm.envAddress("PROOFS_AGGREGATORS_FACTORY");
        address parentHashFetcher = vm.envAddress("PARENT_HASH_FETCHER");
        address messagesInbox = vm.envAddress("MESSAGES_INBOX");

        vm.startBroadcast(deployerPrivateKey);

        L1ToL1MessagesSender l1ToL1MessagesSender = new L1ToL1MessagesSender(
            ISharpProofsAggregatorsFactory(proofsAggregatorsFactory),
            IParentHashFetcher(parentHashFetcher),
            messagesInbox
        );

        vm.stopBroadcast();
    }
}

