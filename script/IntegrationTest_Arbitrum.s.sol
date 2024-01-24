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
        bytes32 expectedBlockHash = 0xe278dc4590304d2f0579689fb1bdd76a08ceac0e0e37bc426e1357e5d8395e1c;
        bytes memory rlpHeader =
            "0xf90222a040a0b2f9b4eb33242268de3003e64779a3b1292a5cd56529af9dfff8523e7a60a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794a4b000000000000000000073657175656e636572a021894e4bbacc76e11bf0e9fbc8170e75d8f03047f4d4dfa3b13634833d14ee80a008f4b87f4465e58296af2672b30596181bf3a7c770311e62cdc357896be7b393a04ab51dcac2b8ef2e196d9e3363683b7c8720c0a6664cf2cf7ed89adfd2b71e0ab90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000183050f5c87040000000000008291008465003c7aa0b5d8a5da3828de54e5a1d8a9624a799331ddac5100bd2df5d6cc11cdb990521aa000000000000016830000000000413418000000000000000a00000000000000008800000000000241678405f5e100";
        uint256 blockNumber = 0x50f5c;
        bytes memory rlpHeaderFromFFI = _getRlpBlockHeader(blockNumber);

        // assert(bytesEqual(rlpHeaderFromFFI, rlpHeader));

        bytes32 blockhashFromHeaderFFI = keccak256(rlpHeaderFromFFI);
        bytes32 blockhashFromHeader = keccak256(rlpHeader);
        // 0xb1c0604deeae132d02982e97418fb07fc9c86473cb5347b9beecf75e1f389a64
        console.logBytes32(blockhashFromHeader);
        // 0xb393713bd4534bf6f38fe8cc7d6ea45df97fe38aaee2db14649cd4db68818d13
        console.logBytes32(blockhashFromHeaderFFI);
        assert(blockhashFromHeader == expectedBlockHash);

        bytes memory _parentHashFetcherCtx = abi.encode(outputRoot, rlpHeader);

        /// Context for L1ToArbitrumMessagesSender contract
        uint256 l2GasLimit = 0x1000000;
        uint256 maxFeePerGas = 0x1;
        uint256 maxSubmissionCost = 0x1;
        bytes memory _xDomainMsgGasData = abi.encode(l2GasLimit, maxFeePerGas, maxSubmissionCost);

        l1ToArbitrumMessagesSender.sendExactParentHashToL2(_parentHashFetcherCtx, _xDomainMsgGasData);
    }

    function testVerifyMessagesIsCorrect() public {
        // To make a test in this way, Somehow `MessagesInbox` this contract should expose a function to verify the messages is correct ( right now we don't have it :/ )
        // Also another consideration : Maybe need to wait for the message to be processed in L2
    }

    function run() public {
        setUp();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.selectFork(sepoliaChainId);
        vm.startBroadcast(deployerPrivateKey);
        testSendMessages();
        vm.stopBroadcast();

        vm.selectFork(arbitrumSepoliaChainId);
        vm.startBroadcast(deployerPrivateKey);
        testVerifyMessagesIsCorrect();
        vm.stopBroadcast();
    }

    function _getRlpBlockHeader(uint256 blockNumber) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = Strings.toString(blockNumber);
        bytes memory headerRlp = vm.ffi(inputs);
        return headerRlp;
    }

    function bytesEqual(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
}
