// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {HeadersProcessor} from "../src/core/HeadersProcessor.sol";
import {console2} from "forge-std/console2.sol";

contract Deploy_HeadersProcessor is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address messagesInbox = vm.envAddress("MESSAGES_INBOX");

        vm.startBroadcast(deployerPrivateKey);

        HeadersProcessor headersProcessor = new HeadersProcessor(messagesInbox);

        console2.log("HeadersProcessor deployed at address: %s", address(headersProcessor));

        vm.stopBroadcast();
    }
}
