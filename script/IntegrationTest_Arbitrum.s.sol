// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MessagesInbox} from "src/core/MessagesInbox.sol";
import {L1ToArbitrumMessagesSender} from "src/core/x-rollup-messaging/L1ToArbitrumMessagesSender.sol";

/// @title IntegrationTest
/// @author Herodotus
/// @notice Integration tests for
contract IntegrationTest_Arbitrum is Script {
    string public ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ALCHEMY_URL");
    string public ETHEREUM_SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");

    uint256 public ethereumSepoliaChainForkId = vm.createFork(ETHEREUM_SEPOLIA_RPC_URL);
    uint256 public arbitrumSepoliaChainForkId = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);

    MessagesInbox public messagesInbox;
    L1ToArbitrumMessagesSender public l1ToArbitrumMessagesSender;

    // This should be deployed in Arbitrum chain
    address public messagesInboxAddress = vm.envAddress("MESSAGES_INBOX");

    // This should be deployed in Ethereum chain
    address public l1ToArbitrumMessageSenderAddress = vm.envAddress("L1_TO_ARBITRUM_MESSAGES_SENDER");

    function setUp() public {
        messagesInbox = MessagesInbox(messagesInboxAddress);
        assert(address(messagesInbox) != address(0));
        l1ToArbitrumMessagesSender = L1ToArbitrumMessagesSender(l1ToArbitrumMessageSenderAddress);
        assert(address(l1ToArbitrumMessagesSender) != address(0));
    }

    // Script for L1ToArbitrumMessagesSender contract to send messages to L2
    function testSendMessages() public {
        /// Context for parent hash fetcher
        bytes32 outputRoot = 0xb5d8a5da3828de54e5a1d8a9624a799331ddac5100bd2df5d6cc11cdb990521a;
        bytes32 expectedBlockHash = 0xe278dc4590304d2f0579689fb1bdd76a08ceac0e0e37bc426e1357e5d8395e1c;
        uint256 blockNumber = 0x50f5c;
        bytes memory rlpHeaderFromRPC = _getRlpBlockHeader(blockNumber);
        bytes32 blockHashFromHeader = keccak256(rlpHeaderFromRPC);

        /// Verify if the block header is correct
        assert(blockHashFromHeader == expectedBlockHash);
        bytes memory _parentHashFetcherCtx = abi.encode(outputRoot, rlpHeaderFromRPC);
        console.logBytes(_parentHashFetcherCtx);

        /// Context for L1ToArbitrumMessagesSender contract
        uint256 l2GasLimit = 0x1000000;
        uint256 maxFeePerGas = 0x1;
        uint256 maxSubmissionCost = 0x1;
        bytes memory _xDomainMsgGasData = abi.encode(l2GasLimit, maxFeePerGas, maxSubmissionCost);
        console.logBytes(_xDomainMsgGasData);

        // Send messages to L2
        l1ToArbitrumMessagesSender.sendExactParentHashToL2(_parentHashFetcherCtx, _xDomainMsgGasData);
    }

    function testVerifyMessagesIsCorrect() public {
        // To make a test in this way, Somehow `MessagesInbox` this contract should expose a function to verify the messages is correct ( right now we don't have it :/ )
        // Also another consideration : Maybe need to wait for the message to be processed in L2
    }

    function run() public {
        setUp();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.selectFork(ethereumSepoliaChainForkId);
        vm.startBroadcast(deployerPrivateKey);
        testSendMessages();
        vm.stopBroadcast();

        // vm.selectFork(arbitrumSepoliaChainId);
        // vm.startBroadcast(deployerPrivateKey);
        // testVerifyMessagesIsCorrect();
        // vm.stopBroadcast();
    }

    function _getRlpBlockHeader(uint256 blockNumber) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = Strings.toString(blockNumber);
        bytes memory headerRlp = vm.ffi(inputs);
        return headerRlp;
    }
}
