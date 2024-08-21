// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {HeadersStore} from "src/core/HeadersStore.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_HeadersStore is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address messagesInbox = vm.envAddress("MESSAGES_INBOX");

        vm.startBroadcast(deployerPrivateKey);

        HeadersStore headersStore = new HeadersStore(messagesInbox);

        console2.log("HeadersStore deployed at address: %s", address(headersStore));

        vm.stopBroadcast();
    }
}
