// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {EOA} from "./helpers/EOA.sol";
import {WETHMock} from "./helpers/WETHMock.sol";
import {IHeadersProcessor} from "../src/interfaces/IHeadersProcessor.sol";
import {IValidityProofVerifier} from "../src/interfaces/IValidityProofVerifier.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";
import {FactsRegistry} from "../src/FactsRegistry.sol";

import {CommitmentsInbox} from "../src/CommitmentsInbox.sol";
import {MsgSignerMock} from "./mocks/MsgSignerMock.sol";

uint256 constant DEFAULT_TREE_ID = 0;

contract FactsRegistry_Test is Test {
    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // TODO replace with proper value

    FactsRegistry private factsRegistry;

    EOA private owner;
    WETHMock private collateral;

    HeadersProcessor private headersProcessor;
    MsgSignerMock private msgSigner;

    CommitmentsInbox private commitmentsInbox;

    event AccountProven(address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash);

    event TransactionProven(uint256 blockNumber, bytes32 rlpEncodedTxIndex, bytes rlpEncodedTx);

    constructor() {
        owner = new EOA();

        collateral = new WETHMock();
        msgSigner = new MsgSignerMock();

        commitmentsInbox = new CommitmentsInbox(msgSigner, IERC20(address(collateral)), 0, address(owner), address(0));
        headersProcessor = new HeadersProcessor(commitmentsInbox, IValidityProofVerifier(address(0)));
        commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
        vm.startPrank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(7583803, 0x139d2f5b484e3ecb9e684096e93c6e6eb008a76ca7afa69aea3d91875c435604);
        headersProcessor.receiveParentHash(6302344, 0x477fc2a372007f6423add99ce363034b68169946a1fc82934ebfdec9bd1a5981);
        headersProcessor.receiveParentHash(13843671, 0x62a8a05ef6fcd39a11b2d642d4b7ab177056e1eb4bde4454f67285164ef8ce65);
        headersProcessor.receiveParentHash(90006, 0x110e1bd97bed8bab4f08039edd0327b3341002881a48cd8f2d3df481e9b6d6d4);
        vm.stopPrank();
        factsRegistry = new FactsRegistry(headersProcessor);
    }

    function processBlockFromMessage() public returns (bytes memory, bytes32[] memory) {
        uint256 blockNumber = 7583802;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = "7583802";
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);

        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, blockNumber, headerRlp_1, new bytes32[](0));

        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp_1)));
        return (headerRlp_1, nextPeaks);
    }

    function test_proveAccount_emptyAccount() public {
        (bytes memory headerRlp, bytes32[] memory peaks) = processBlockFromMessage();

        string[] memory inputs = new string[](6);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_state_proof.js";
        inputs[2] = "7583802";
        inputs[3] = "0x456cb24d30eaa6affc2a6924dae0d2a0a8c99c73";
        inputs[4] = "0x54cdd369e4e8a8515e52ca72ec816c2101831ad1f18bf44102ed171459c9b4f8";
        inputs[5] = "account";
        bytes memory proof = vm.ffi(inputs);

        uint16 bitmap = 15; // 0b1111
        uint256 blockNumber = 7583802;
        address account = address(uint160(uint256(0x00456cb24d30eaa6affc2a6924dae0d2a0a8c99c73)));

        factsRegistry.proveAccount(
            DEFAULT_TREE_ID,
            bitmap,
            blockNumber,
            account,
            1,
            keccak256(headerRlp),
            headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
            new bytes32[](0),
            peaks,
            headerRlp,
            proof
        );

        uint256 balance = factsRegistry.accountBalances(account, blockNumber);
        uint256 nonce = factsRegistry.accountNonces(account, blockNumber);
        bytes32 storageHash = factsRegistry.accountStorageHashes(account, blockNumber);
        bytes32 codeHash = factsRegistry.accountCodeHashes(account, blockNumber);
        assertEq(balance, 0);
        assertEq(nonce, 0);
        assertEq(storageHash, EMPTY_TRIE_ROOT_HASH);
        assertEq(codeHash, EMPTY_CODE_HASH);
    }

    function test_proveAccount_nonEmptyAccount() public {
        (bytes memory headerRlp, bytes32[] memory peaks) = processBlockFromMessage();

        string[] memory inputs = new string[](6);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_state_proof.js";
        inputs[2] = "7583802";
        inputs[3] = "0x7b2f05cE9aE365c3DBF30657e2DC6449989e83D6";
        inputs[4] = "0x0000000000000000000000000000000000000000000000000000000000000033";
        inputs[5] = "account";
        bytes memory proof = vm.ffi(inputs);

        uint16 bitmap = 15; // 0b1111
        uint256 blockNumber = 7583802;
        address account = address(uint160(uint256(0x007b2f05cE9aE365c3DBF30657e2DC6449989e83D6)));

        vm.expectEmit(true, true, true, true);
        emit AccountProven(
            account,
            blockNumber,
            1,
            0,
            0xcd4f25236fff0ccac15e82bf4581beb08e95e1b5ba89de6031c75893cd91245c,
            0x1c35dfde2b62d99d3a74fda76446b60962c4656814bdd7815eb6e5b8be1e7185
        );
        factsRegistry.proveAccount(
            DEFAULT_TREE_ID,
            bitmap,
            blockNumber,
            account,
            1,
            keccak256(headerRlp),
            headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
            new bytes32[](0),
            peaks,
            headerRlp,
            proof
        );

        uint256 balance = factsRegistry.accountBalances(account, blockNumber);
        uint256 nonce = factsRegistry.accountNonces(account, blockNumber);
        bytes32 storageHash = factsRegistry.accountStorageHashes(account, blockNumber);
        bytes32 codeHash = factsRegistry.accountCodeHashes(account, blockNumber);
        assertEq(balance, 0);
        assertEq(nonce, 1);
        assertEq(storageHash, 0x1c35dfde2b62d99d3a74fda76446b60962c4656814bdd7815eb6e5b8be1e7185);
        assertEq(codeHash, 0xcd4f25236fff0ccac15e82bf4581beb08e95e1b5ba89de6031c75893cd91245c);
    }

    function test_proveAccount_revert() public {
        (bytes memory headerRlp, bytes32[] memory peaks) = processBlockFromMessage();

        string[] memory inputs = new string[](6);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_state_proof.js";
        inputs[2] = "7583802";
        inputs[3] = "0x456cb24d30eaa6affc2a6924dae0d2a0a8c99c73";
        inputs[4] = "0x54cdd369e4e8a8515e52ca72ec816c2101831ad1f18bf44102ed171459c9b4f8";
        inputs[5] = "account";
        bytes memory proof = vm.ffi(inputs);

        uint16 bitmap = 15; // 0b1111
        uint256 blockNumber = 7583802;
        address account = address(uint160(uint256(0x00456cb24d30eaa6affc2a6924dae0d2a0a8c99c73)));

        // Test wrong elements count
        uint256 invalidElementsCount = 0;
        vm.expectRevert("ERR_EMPTY_MMR_ROOT");
        factsRegistry.proveAccount(DEFAULT_TREE_ID, bitmap, blockNumber, account, 1, keccak256(headerRlp), invalidElementsCount, new bytes32[](0), peaks, headerRlp, proof);

        // Test wrong peaks
        bytes32[] memory invalidPeaks = new bytes32[](1);
        invalidPeaks[0] = keccak256(abi.encode(42, keccak256(headerRlp)));

        (bool status, ) = address(factsRegistry).call(
            abi.encodeWithSignature(
                "proveAccount(uint16,uint256,address,uint256,bytes32,uint256,bytes32[],bytes32[],bytes,bytes)",
                bitmap,
                blockNumber,
                account,
                1,
                keccak256(headerRlp),
                headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
                new bytes32[](0),
                invalidPeaks,
                headerRlp,
                proof
            )
        );
        assertFalse(status);

        // Test malicious RLP header
        string[] memory rlp_inputs_malicious = new string[](4);
        rlp_inputs_malicious[0] = "node";
        rlp_inputs_malicious[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_malicious[2] = "7583802";
        rlp_inputs_malicious[3] = "malicious";
        bytes memory headerRlp_malicious = vm.ffi(rlp_inputs_malicious);

        (status, ) = address(factsRegistry).call(
            abi.encodeWithSignature(
                "proveAccount(uint16,uint256,address,uint256,bytes32,uint256,bytes32[],bytes32[],bytes,bytes)",
                bitmap,
                blockNumber,
                account,
                1,
                keccak256(headerRlp),
                headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
                new bytes32[](0),
                peaks,
                headerRlp_malicious,
                proof
            )
        );
        assertFalse(status);
    }

    function test_proveStorage() public {
        (bytes memory headerRlp, bytes32[] memory peaks) = processBlockFromMessage();

        string[] memory accountProof_inputs = new string[](6);
        accountProof_inputs[0] = "node";
        accountProof_inputs[1] = "./helpers/fetch_state_proof.js";
        accountProof_inputs[2] = "7583802";
        accountProof_inputs[3] = "0x7b2f05cE9aE365c3DBF30657e2DC6449989e83D6";
        accountProof_inputs[4] = "0x0000000000000000000000000000000000000000000000000000000000000033";
        accountProof_inputs[5] = "account";
        bytes memory accountProof = vm.ffi(accountProof_inputs);

        uint256 blockNumber = 7583802;
        address account = address(uint160(uint256(0x007b2f05cE9aE365c3DBF30657e2DC6449989e83D6)));

        uint16 bitmap = 15; // 0b1111
        factsRegistry.proveAccount(
            DEFAULT_TREE_ID,
            bitmap,
            blockNumber,
            account,
            1,
            keccak256(headerRlp),
            headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
            new bytes32[](0),
            peaks,
            headerRlp,
            accountProof
        );

        string[] memory storageProof_inputs = new string[](6);
        storageProof_inputs[0] = "node";
        storageProof_inputs[1] = "./helpers/fetch_state_proof.js";
        storageProof_inputs[2] = "7583802";
        storageProof_inputs[3] = "0x7b2f05cE9aE365c3DBF30657e2DC6449989e83D6";
        storageProof_inputs[4] = "0x0000000000000000000000000000000000000000000000000000000000000033";
        storageProof_inputs[5] = "slot";
        bytes memory storageProof = vm.ffi(storageProof_inputs);

        bytes32 slot = 0x0000000000000000000000000000000000000000000000000000000000000033;

        bytes32 value = factsRegistry.proveStorage(account, blockNumber, slot, storageProof);
        assertEq(value, bytes32(uint256(uint160(0x00ef7b1e0ddea68cad3d74fbb7a03e6ccde3091286))));
    }

    // External helper function (used for test purposes only)
    function encodeUint(uint256 value) internal pure returns (bytes memory) {
        // allocate our result bytes
        bytes memory result = new bytes(33);

        if (value == 0) {
            // store length = 1, value = 0x80
            assembly {
                mstore(add(result, 1), 0x180)
            }
            return result;
        }

        if (value < 128) {
            // store length = 1, value = value
            assembly {
                mstore(add(result, 1), or(0x100, value))
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 33, prefix 0xa0 followed by value
            assembly {
                mstore(add(result, 1), 0x21a0)
                mstore(add(result, 33), value)
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 32, prefix 0x9f followed by value
            assembly {
                mstore(add(result, 1), 0x209f)
                mstore(add(result, 33), shl(8, value))
            }
            return result;
        }

        assembly {
            let length := 1
            for {
                let min := 0x100
            } lt(sub(min, 1), value) {
                min := shl(8, min)
            } {
                length := add(length, 1)
            }

            let bytesLength := add(length, 1)

            // bytes length field
            let hi := shl(mul(bytesLength, 8), bytesLength)

            // rlp encoding of value
            let lo := or(shl(mul(length, 8), add(length, 0x80)), value)

            mstore(add(result, bytesLength), or(hi, lo))
        }
        return result;
    }

    function test_proveReceipt() public {
        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = "6302343";
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, 6302343, headerRlp, new bytes32[](0));

        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp)));

        string[] memory receiptProofInputs = new string[](3);
        receiptProofInputs[0] = "node";
        receiptProofInputs[1] = "./helpers/fetch_receipts_proof.js";
        receiptProofInputs[2] = "0x602a87";
        bytes memory receiptProof = vm.ffi(receiptProofInputs);

        uint256 transactionIndex = 0x31;
        bytes32 rlpEncodedTxIndex = bytes32(encodeUint(transactionIndex));

        bytes
            memory expectedEncodedRlp = hex"f9010901836271b0b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0";

        uint16 bitmap = 15; // 0b1111
        vm.expectEmit(true, true, true, true);
        emit TransactionProven(6302343, rlpEncodedTxIndex, expectedEncodedRlp);
        factsRegistry.proveTransactionReceipt(
            DEFAULT_TREE_ID,
            bitmap,
            6302343,
            rlpEncodedTxIndex,
            1,
            keccak256(headerRlp),
            headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
            new bytes32[](0),
            nextPeaks,
            headerRlp,
            receiptProof
        );

        // Check tx status is 1
        assertEq(factsRegistry.transactionStatuses(6302343, rlpEncodedTxIndex), 1);
        // Check cumulative gas used is correct
        assertEq(factsRegistry.transactionsCumulativeGasUsed(6302343, rlpEncodedTxIndex), 0x6271b0);
        // Check logs bloom is correct
        assertEq(
            factsRegistry.transactionsLogsBlooms(6302343, rlpEncodedTxIndex),
            bytes(
                hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            )
        );
        // Check logs are correct
        assertEq(factsRegistry.transactionsLogs(6302343, rlpEncodedTxIndex), bytes(hex"c0")); // 0xc0 is RLP for empty list
    }

    function test_proveReceiptWithFailedTx() public {
        string[] memory rlp_inputs = new string[](3);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = "90005";

        bytes memory headerRlp = vm.ffi(rlp_inputs);

        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, 90005, headerRlp, new bytes32[](0));

        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp)));

        string[] memory receiptProofInputs = new string[](3);
        receiptProofInputs[0] = "node";
        receiptProofInputs[1] = "./helpers/fetch_receipts_proof.js";
        receiptProofInputs[2] = "0x15f95";
        bytes memory receiptProof = vm.ffi(receiptProofInputs);

        uint256 transactionIndex = 0x0;
        bytes32 rlpEncodedTxIndex = bytes32(encodeUint(transactionIndex));

        bytes
            memory expectedEncodedRlp = hex"f90108808274f0b9010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0";

        uint16 bitmap = 15; // 0b1111
        vm.expectEmit(true, true, true, true);
        emit TransactionProven(90005, rlpEncodedTxIndex, expectedEncodedRlp);
        factsRegistry.proveTransactionReceipt(
            DEFAULT_TREE_ID,
            bitmap,
            90005,
            rlpEncodedTxIndex,
            1,
            keccak256(headerRlp),
            headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
            new bytes32[](0),
            nextPeaks,
            headerRlp,
            receiptProof
        );

        // Check tx status is 0
        assertEq(factsRegistry.transactionStatuses(90005, rlpEncodedTxIndex), 0);
        // Check cumulative gas used is correct
        assertEq(factsRegistry.transactionsCumulativeGasUsed(90005, rlpEncodedTxIndex), 0x74f0);
        // // Check logs bloom is correct
        assertEq(
            factsRegistry.transactionsLogsBlooms(90005, rlpEncodedTxIndex),
            bytes(
                hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            )
        );
        // // Check logs are correct
        assertEq(factsRegistry.transactionsLogs(90005, rlpEncodedTxIndex), bytes(hex"c0")); // 0xc0 is RLP for empty list
    }

    function test_proveReceiptWithLogs() public {
        string[] memory rlp_inputs = new string[](4);
        rlp_inputs[0] = "node";
        rlp_inputs[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs[2] = "13843670";
        rlp_inputs[3] = "mainnet";
        bytes memory headerRlp = vm.ffi(rlp_inputs);

        headersProcessor.processBlockFromMessage(DEFAULT_TREE_ID, 13843670, headerRlp, new bytes32[](0));

        bytes32[] memory nextPeaks = new bytes32[](1);
        nextPeaks[0] = keccak256(abi.encode(1, keccak256(headerRlp)));

        string[] memory receiptProofInputs = new string[](3);
        receiptProofInputs[0] = "node";
        receiptProofInputs[1] = "./helpers/fetch_receipts_proof.js";
        receiptProofInputs[2] = "0xd33cd6";
        bytes memory receiptProof = vm.ffi(receiptProofInputs);

        uint256 transactionIndex = 0xba;
        bytes32 rlpEncodedTxIndex = bytes32(encodeUint(transactionIndex));

        bytes
            memory expectedEncodedRlp = hex"f907120183d0d08eb9010000000000000008000000000000100100000010000000000000000100100000000000000040000000000000000000000000000000000010000000000000120000000000400000000040000008000000000080000004001000000000010000000000000000020040000000000000200800000000000000000000000010000000000000010000000000800000000000000004000000000000080000004040000000008000000202040008804000050000000004000000000000000000040000000000000002000002000000000000004000000000000000000000000000000020000000000000000000000000000104000000000000000000000040000000002002f90607f89c9457f1887a8bf19b14fc0df6fd9b2acc9af147ea85f884a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa00000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5a0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3f80f89b9400000000000c2e074ec69a0dfb2997ba6c7d2e1ef863a0ce0457fe73731f824cc272376169235128c118b49d344817417c6d108d155e82a093cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4aea0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5f89b9457f1887a8bf19b14fc0df6fd9b2acc9af147ea85f863a0b3d987963d01b2f68493b4bdb130988f157ea43070d4ad840fee0466ed9370d9a0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5a000000000000000000000000000000000000000000000000000000000748fff67f87a9400000000000c2e074ec69a0dfb2997ba6c7d2e1ef842a0335721b01866dc23fbee8b6b2c7b1e14d6f05c28cd35a2c934239f94095602a0a04fa51a342e5eed6d5de5b493b63f74f51639cc157e1cbdd3767ccd354ebb2b72a00000000000000000000000004976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41f8db944976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41f842a065412581168e88a1e60c6459d7f44ae83ad0832e670826c05a4e2476b57af752a04fa51a342e5eed6d5de5b493b63f74f51639cc157e1cbdd3767ccd354ebb2b72b880000000000000000000000000000000000000000000000000000000000000003c00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000014cadd3f807571ef68d3b0d31458260a928e144c2a000000000000000000000000f87a944976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41f842a052d7d861f09ab3d26239d492e8968629f95e9e318cf0b73bfddc441522a15fd2a04fa51a342e5eed6d5de5b493b63f74f51639cc157e1cbdd3767ccd354ebb2b72a0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2af89b9400000000000c2e074ec69a0dfb2997ba6c7d2e1ef863a0ce0457fe73731f824cc272376169235128c118b49d344817417c6d108d155e82a093cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4aea0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2af89c9457f1887a8bf19b14fc0df6fd9b2acc9af147ea85f884a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5a0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2aa0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3f80f9011c94283af0b28c62c092c9727f1ee09c02ca627eb7f5f863a0ca6abbe9d7f11422cb6ca7629fbf6fe9efb1c621f71ce8f02b9f2a230097404fa0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2ab8a00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000002e45f57549f85000000000000000000000000000000000000000000000000000000000748fff6700000000000000000000000000000000000000000000000000000000000000137465736c61656c656374726963747275636b7300000000000000000000000000"; // todo: add real one

        uint16 bitmap = 15; // 0b1111
        vm.expectEmit(true, true, true, true);
        emit TransactionProven(13843670, rlpEncodedTxIndex, expectedEncodedRlp);
        factsRegistry.proveTransactionReceipt(
            DEFAULT_TREE_ID,
            bitmap,
            13843670,
            rlpEncodedTxIndex,
            1,
            keccak256(headerRlp),
            headersProcessor.mmrsElementsCount(DEFAULT_TREE_ID),
            new bytes32[](0),
            nextPeaks,
            headerRlp,
            receiptProof
        );

        // Check tx status is 1
        assertEq(factsRegistry.transactionStatuses(13843670, rlpEncodedTxIndex), 1);
        // Check cumulative gas used is correct
        assertEq(factsRegistry.transactionsCumulativeGasUsed(13843670, rlpEncodedTxIndex), 0xd0d08e);
        // Check logs bloom is correct
        assertEq(
            factsRegistry.transactionsLogsBlooms(13843670, rlpEncodedTxIndex),
            bytes(
                hex"00000000000008000000000000100100000010000000000000000100100000000000000040000000000000000000000000000000000010000000000000120000000000400000000040000008000000000080000004001000000000010000000000000000020040000000000000200800000000000000000000000010000000000000010000000000800000000000000004000000000000080000004040000000008000000202040008804000050000000004000000000000000000040000000000000002000002000000000000004000000000000000000000000000000020000000000000000000000000000104000000000000000000000040000000002002"
            )
        );
        // Check logs are correct
        assertEq(
            factsRegistry.transactionsLogs(13843670, rlpEncodedTxIndex),
            bytes(
                hex"f90607f89c9457f1887a8bf19b14fc0df6fd9b2acc9af147ea85f884a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa00000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5a0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3f80f89b9400000000000c2e074ec69a0dfb2997ba6c7d2e1ef863a0ce0457fe73731f824cc272376169235128c118b49d344817417c6d108d155e82a093cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4aea0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5f89b9457f1887a8bf19b14fc0df6fd9b2acc9af147ea85f863a0b3d987963d01b2f68493b4bdb130988f157ea43070d4ad840fee0466ed9370d9a0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5a000000000000000000000000000000000000000000000000000000000748fff67f87a9400000000000c2e074ec69a0dfb2997ba6c7d2e1ef842a0335721b01866dc23fbee8b6b2c7b1e14d6f05c28cd35a2c934239f94095602a0a04fa51a342e5eed6d5de5b493b63f74f51639cc157e1cbdd3767ccd354ebb2b72a00000000000000000000000004976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41f8db944976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41f842a065412581168e88a1e60c6459d7f44ae83ad0832e670826c05a4e2476b57af752a04fa51a342e5eed6d5de5b493b63f74f51639cc157e1cbdd3767ccd354ebb2b72b880000000000000000000000000000000000000000000000000000000000000003c00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000014cadd3f807571ef68d3b0d31458260a928e144c2a000000000000000000000000f87a944976fb03c32e5b8cfe2b6ccb31c09ba78ebaba41f842a052d7d861f09ab3d26239d492e8968629f95e9e318cf0b73bfddc441522a15fd2a04fa51a342e5eed6d5de5b493b63f74f51639cc157e1cbdd3767ccd354ebb2b72a0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2af89b9400000000000c2e074ec69a0dfb2997ba6c7d2e1ef863a0ce0457fe73731f824cc272376169235128c118b49d344817417c6d108d155e82a093cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4aea0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2af89c9457f1887a8bf19b14fc0df6fd9b2acc9af147ea85f884a0ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa0000000000000000000000000283af0b28c62c092c9727f1ee09c02ca627eb7f5a0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2aa0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3f80f9011c94283af0b28c62c092c9727f1ee09c02ca627eb7f5f863a0ca6abbe9d7f11422cb6ca7629fbf6fe9efb1c621f71ce8f02b9f2a230097404fa0eb7f8f3913b15412ae78c117605578343d564f08f09113d4e41ca387ed8c1e3fa0000000000000000000000000cadd3f807571ef68d3b0d31458260a928e144c2ab8a00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000002e45f57549f85000000000000000000000000000000000000000000000000000000000748fff6700000000000000000000000000000000000000000000000000000000000000137465736c61656c656374726963747275636b7300000000000000000000000000"
            )
        );
    }
}
