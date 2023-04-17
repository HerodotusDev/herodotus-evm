// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {EOA} from "./helpers/EOA.sol";
import {WETHMock} from "./helpers/WETHMock.sol";
import {IHeadersProcessor} from "../src/interfaces/IHeadersProcessor.sol";
import {HeadersProcessor} from "../src/HeadersProcessor.sol";
import {FactsRegistry} from "../src/FactsRegistry.sol";

import {CommitmentsInbox} from "../src/CommitmentsInbox.sol";
import {MsgSignerMock} from "./mocks/MsgSignerMock.sol";

contract FactsRegistry_Test is Test {
    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // TODO replace with proper value

    FactsRegistry private factsRegistry;

    EOA private owner;
    WETHMock private collateral;

    HeadersProcessor private headersProcessor;
    MsgSignerMock private msgSigner;

    CommitmentsInbox private commitmentsInbox;

    constructor() {
        owner = new EOA();

        collateral = new WETHMock();
        msgSigner = new MsgSignerMock();

        commitmentsInbox = new CommitmentsInbox(msgSigner, IERC20(address(collateral)), 0, address(owner), address(0));
        headersProcessor = new HeadersProcessor(commitmentsInbox);
        commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
        vm.prank(address(commitmentsInbox));
        headersProcessor.receiveParentHash(7583803, 0x139d2f5b484e3ecb9e684096e93c6e6eb008a76ca7afa69aea3d91875c435604);

        factsRegistry = new FactsRegistry(headersProcessor);
    }

    function processBlockFromMessage() public returns (bytes memory, bytes32[] memory) {
        uint256 blockNumber = 7583802;
        string[] memory rlp_inputs_1 = new string[](3);
        rlp_inputs_1[0] = "node";
        rlp_inputs_1[1] = "./helpers/fetch_header_rlp.js";
        rlp_inputs_1[2] = "7583802";
        bytes memory headerRlp_1 = vm.ffi(rlp_inputs_1);

        headersProcessor.processBlockFromMessage(blockNumber, headerRlp_1, new bytes32[](0));

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

        factsRegistry.proveAccount(bitmap, blockNumber, account, 1, keccak256(headerRlp), headersProcessor.mmrElementsCount(), new bytes32[](0), peaks, headerRlp, proof);

        assertEq(factsRegistry.accountBalances(account, blockNumber), 0);
        assertEq(factsRegistry.accountNonces(account, blockNumber), 0);
        assertEq(factsRegistry.accountStorageHashes(account, blockNumber), EMPTY_TRIE_ROOT_HASH);
        assertEq(factsRegistry.accountCodeHashes(account, blockNumber), EMPTY_CODE_HASH);
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

        factsRegistry.proveAccount(bitmap, blockNumber, account, 1, keccak256(headerRlp), headersProcessor.mmrElementsCount(), new bytes32[](0), peaks, headerRlp, proof);

        assertEq(factsRegistry.accountBalances(account, blockNumber), 0);
        assertEq(factsRegistry.accountNonces(account, blockNumber), 1);
        assertEq(factsRegistry.accountStorageHashes(account, blockNumber), 0x1c35dfde2b62d99d3a74fda76446b60962c4656814bdd7815eb6e5b8be1e7185);
        assertEq(factsRegistry.accountCodeHashes(account, blockNumber), 0xcd4f25236fff0ccac15e82bf4581beb08e95e1b5ba89de6031c75893cd91245c);
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
        factsRegistry.proveAccount(bitmap, blockNumber, account, 1, keccak256(headerRlp), headersProcessor.mmrElementsCount(), new bytes32[](0), peaks, headerRlp, accountProof);

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
}
