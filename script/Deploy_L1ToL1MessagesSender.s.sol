// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {L1ToL1MessagesSender} from "src/core/x-rollup-messaging/outbox/L1ToL1MessagesSender.sol";
import {IParentHashFetcher} from "src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";
import {ISharpProofsAggregatorsFactory} from "src/core/interfaces/ISharpProofsAggregatorsFactory.sol";

import {SimpleMessagesInbox} from "src/core/x-rollup-messaging/inbox/SimpleMessagesInbox.sol";
import {HeadersStore} from "src/core/HeadersStore.sol";
import {FactsRegistry} from "src/core/FactsRegistry.sol";

contract Deploy_L1ToL1MessagesSender is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address proofsAggregatorsFactory = vm.envAddress("PROOFS_AGGREGATORS_FACTORY");
        address parentHashFetcher = vm.envAddress("PARENT_HASH_FETCHER");

        SimpleMessagesInbox messagesInbox = new SimpleMessagesInbox();

        HeadersStore headersStore = new HeadersStore(address(messagesInbox));

        FactsRegistry factsRegistry = new FactsRegistry(address(headersStore));

        L1ToL1MessagesSender l1ToL1MessagesSender = new L1ToL1MessagesSender(
            ISharpProofsAggregatorsFactory(proofsAggregatorsFactory),
            IParentHashFetcher(parentHashFetcher),
            address(messagesInbox)
        );

        messagesInbox.setCrossDomainMsgSender(address(l1ToL1MessagesSender));
        messagesInbox.setHeadersStore(address(headersStore));
        messagesInbox.setMessagesOriginChainId(5);

        console.log("MessagesInbox deployed at address: %s", address(messagesInbox));
        console.log("HeadersStore deployed at address: %s", address(headersStore));
        console.log("FactsRegistry deployed at address: %s", address(factsRegistry));
        console.log("L1ToL1MessagesSender deployed at address: %s", address(l1ToL1MessagesSender));

        vm.stopBroadcast();
    }
}
