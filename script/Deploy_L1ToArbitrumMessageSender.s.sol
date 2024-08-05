// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {L1ToArbitrumMessagesSender} from "../src/core/x-rollup-messaging/L1ToArbitrumMessagesSender.sol";
import {IArbitrumInbox} from "../src/core/x-rollup-messaging/interfaces/IArbitrumInbox.sol";
import {IParentHashFetcher} from "../src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";
import {ISharpProofsAggregatorsFactory} from "../src/core/interfaces/ISharpProofsAggregatorsFactory.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_L1ToArbitrumMessagesSender is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address proofsAggregatorsFactory = vm.envAddress("PROOFS_AGGREGATORS_FACTORY");
        address parentHashFetcher = vm.envAddress("PARENT_HASH_FETCHER");
        address l2Target = vm.envAddress("L2_TARGET");
        address arbitrumMessenger = vm.envAddress("ARBITRUM_INBOX");

        vm.startBroadcast(deployerPrivateKey);

        L1ToArbitrumMessagesSender l1ToArbitrumMessagesSender = new L1ToArbitrumMessagesSender(
            ISharpProofsAggregatorsFactory(proofsAggregatorsFactory),
            IParentHashFetcher(parentHashFetcher),
            l2Target,
            IArbitrumInbox(arbitrumMessenger)
        );

        console2.log("L1ToArbitrumMessagesSender address: %s", address(l1ToArbitrumMessagesSender));

        vm.stopBroadcast();
    }
}
