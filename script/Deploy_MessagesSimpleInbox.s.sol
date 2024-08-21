// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {SimpleMessagesInbox} from "src/core/x-rollup-messaging/inbox/SimpleMessagesInbox.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_MessagesSimpleInbox is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleMessagesInbox messagesInbox = new SimpleMessagesInbox();

        console2.log("MessagesInbox deployed at address: %s", address(messagesInbox));

        vm.stopBroadcast();
    }
}
