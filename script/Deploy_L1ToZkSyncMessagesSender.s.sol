// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {L1ToZkSyncMessagesSender} from "../src/core/x-rollup-messaging/L1ToZksyncMessagesSender.sol";
import {ISharpProofsAggregatorsFactory} from "../src/core/interfaces/ISharpProofsAggregatorsFactory.sol";
import {IParentHashFetcher} from "../src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";
import {IZkSyncMailbox} from "../src/core/x-rollup-messaging/interfaces/IZkSyncMailbox.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_L1ToZkSyncMessagesSender is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address proofsAggregatorsFactory = vm.envAddress("PROOFS_AGGREGATORS_FACTORY");
        address parentHashFetcher = vm.envAddress("PARENT_HASH_FETCHER");

        vm.startBroadcast(deployerPrivateKey);

        L1ToZkSyncMessagesSender l1ToZkSyncMessagesSender = new L1ToZkSyncMessagesSender(
            ISharpProofsAggregatorsFactory(proofsAggregatorsFactory),
            IParentHashFetcher(parentHashFetcher),
            vm.envAddress("ZKSYNC_HERODOTUS_MESSAGES_INBOX"),
            IZkSyncMailbox(vm.envAddress("ZKSYNC_MAILBOX"))
        );

        console2.log("L1ToZkSyncMessagesSender deployed at address: %s", address(l1ToZkSyncMessagesSender));

        vm.stopBroadcast();
    }
}
