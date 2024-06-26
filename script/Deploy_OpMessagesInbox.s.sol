// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {OpMessagesInbox} from "src/core/x-rollup-messaging/inbox/OpMessagesInbox.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_OpMessagesInbox is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        OpMessagesInbox messagesInbox = new OpMessagesInbox();

        console2.log("MessagesInbox deployed at address: %s", address(messagesInbox));

        vm.stopBroadcast();
    }
}
