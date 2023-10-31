// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {MessagesInbox} from "../src/core/MessagesInbox.sol";


contract Deploy_MessagesInbox is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address crossdomainMsgSender = vm.envAddress("CROSS_DOMAIN_MSG_SENDER");
        uint256 crossdomainMsgsOriginChainId = vm.envUint("CROSS_DOMAIN_MSGS_CHAIN_ID");
        address headersProcessor = vm.envAddress("HEADERS_PROCESSOR");

        vm.startBroadcast(deployerPrivateKey);

        MessagesInbox nativeParentHashesFetcher = new MessagesInbox(crossdomainMsgSender, headersProcessor, crossdomainMsgsOriginChainId);
        vm.stopBroadcast();
    }
}