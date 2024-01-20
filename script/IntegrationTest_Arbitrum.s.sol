// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MessagesInbox} from "src/core/MessagesInbox.sol";
import {L1ToArbitrumMessagesSender} from "src/core/x-rollup-messaging/L1ToArbitrumMessagesSender.sol";

/// @title IntegrationTest
/// @author Herodotus
/// @notice Integration tests for
contract IntegrationTest_Arbitrum is Script {
    string public ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
    string public SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");

    uint256 public sepoliaChainId;
    uint256 public arbitrumSepoliaChainId = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);

    MessagesInbox public messagesInbox;
    L1ToArbitrumMessagesSender public l1ToArbitrumMessagesSender;

    // This should be deployed in L2 chain
    address public messagesInboxAddress = vm.envAddress("MESSAGES_INBOX");

    // This should be deployed in L1 chain
    address public l1ToArbitrumMessageSenderAddress = vm.envAddress("L1_TO_ARBITRUM_MESSAGES_SENDER");

    function setUp() public {
        messagesInbox = MessagesInbox(messagesInboxAddress);
        l1ToArbitrumMessagesSender = L1ToArbitrumMessagesSender(l1ToArbitrumMessageSenderAddress);
    }

    // Script for L1ToArbitrumMessagesSender contract to send messages to L2
    function testSendMessages() public {
        /// Context for parent hash fetcher
        bytes32 outputRoot = 0xb5d8a5da3828de54e5a1d8a9624a799331ddac5100bd2df5d6cc11cdb990521a;
        bytes memory rlpHeader =
            "0xf90206a0e42880406f984925da8bf8e41694509b80a949518eb8f5aa94ae63f369517ba9a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794a4baa0cf4e84967ff0c01790778d65b2889da503a060933f252d476b17767607a40b07e149e2bd184ce8adc96b7d57dc95486344bea0766ead2dc09f232d7cad06728b93f46b5f0f45936a7105d73d4e7425e67e29c7a0f08cf5553e1dae52e3df19b356b8320e17c39fb055f635739c31052db5c3e45eb8ec00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000183050f5c87040000000000008084631e08ffa07af1604ecc592215db28fae4bcfeda90e82486a804382cba40b769bdc4a0d262a000000000000007830000000000ecc06a00000000000000060000000000000000880000000000007d24";
        bytes memory _parentHashFetcherCtx = abi.encode(outputRoot, rlpHeader);

        /// Context for L1ToArbitrumMessagesSender contract
        uint256 l2GasLimit = 0x1;
        uint256 maxFeePerGas = 0x1;
        uint256 maxSubmissionCost = 0x1;
        bytes memory _xDomainMsgGasData = abi.encode(l2GasLimit, maxFeePerGas, maxSubmissionCost);

        l1ToArbitrumMessagesSender.sendExactParentHashToL2(_parentHashFetcherCtx, _xDomainMsgGasData);
    }

    function testVerifyMessagesIsCorrect() public {
        // bytes memory message = abi.encodePacked("Hello World");
        // bytes32 messageHash = keccak256(message);
        // bytes32 inboxTopHash = messagesInbox.inboxAccs(0);

        // l1ToArbitrumMessagesSender = new L1ToArbitrumMessagesSender(address(messagesInbox));

        // l1ToArbitrumMessagesSender.sendMessages(messageHash, inboxTopHash);

        // bytes32 newInboxTopHash = messagesInbox.inboxAccs(0);

        // assertEq(newInboxTopHash, messageHash, "Inbox top hash should be the message hash");
    }

    function run() public {
        setUp();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.selectFork(sepoliaChainId);
        vm.startBroadcast(deployerPrivateKey);
        testSendMessages();
        vm.stopBroadcast();

        // vm.selectFork(arbitrumSepoliaChainId);
        // vm.startBroadcast(deployerPrivateKey);
        // testVerifyMessagesIsCorrect();
        // vm.stopBroadcast();
    }
}
