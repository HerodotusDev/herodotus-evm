// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {MessagesInbox} from "../src/core/MessagesInbox.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_MessagesInbox is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MessagesInbox messagesInbox = new MessagesInbox();

        console2.log("MessagesInbox deployed at address: %s", address(messagesInbox));

        vm.stopBroadcast();
    }
}
