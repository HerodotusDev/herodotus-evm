// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FactsRegistry} from "../src/core/FactsRegistry.sol";
import {Types} from "../src/lib/Types.sol";


uint256 constant DEFAULT_TREE_ID = 0;

contract MockedHeadersProcessor {
    bytes32 constant ROOT_OF_MMR_CONTAINING_BLOCK_7583802_AT_INDEX_1 = 0x7925fc646e7ff14336b092e12adf5b66e8da65a06b14c486c231fcb92ca6c74c;
    uint256 constant SIZE_OF_MMR_CONTAINING_BLOCK_7583802_AT_INDEX_1 = 7;

    function getMMRRoot(uint256 mmrId, uint256 mmrSize) external view returns (bytes32) {
        require(mmrId == DEFAULT_TREE_ID, "ERR_INVALID_MMR_ID");
        require(mmrSize == SIZE_OF_MMR_CONTAINING_BLOCK_7583802_AT_INDEX_1, "ERR_INVALID_MMR_SIZE");
        return ROOT_OF_MMR_CONTAINING_BLOCK_7583802_AT_INDEX_1;
    }
}

contract FactsRegistry_Test is Test {
    using Strings for uint256;


    FactsRegistry private factsRegistry;

    constructor() {
        MockedHeadersProcessor mockedHeadersProcessor = new MockedHeadersProcessor();
        factsRegistry = new FactsRegistry(address(mockedHeadersProcessor));
    }

    function test_proveAccount_accountExists() public {
        uint256 proveForBlock = 7583802;
        address accountToProve = 0x7b2f05cE9aE365c3DBF30657e2DC6449989e83D6;

        _proveAccountWithAddressAtBlock(accountToProve, proveForBlock);

        uint256 expectedNonce = 1;
        uint256 savedNonce = uint256(factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.NONCE));
        assertEq(savedNonce, expectedNonce);

        uint256 expectedBalance = 0;
        uint256 savedBalance = uint256(factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.BALANCE));
        assertEq(savedBalance, expectedBalance);

        bytes32 expectedStorageRoot = 0x1c35dfde2b62d99d3a74fda76446b60962c4656814bdd7815eb6e5b8be1e7185;
        bytes32 accountStorageRoot = factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.STORAGE_ROOT);
        assertEq(accountStorageRoot, expectedStorageRoot);

        bytes32 expectedCodeHash = 0xcd4f25236fff0ccac15e82bf4581beb08e95e1b5ba89de6031c75893cd91245c;
        bytes32 accountCodeHash = factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.CODE_HASH);
        assertEq(accountCodeHash, expectedCodeHash);
    }

    function test_proveAccount_accountDoesNotExist() public {
        uint256 proveForBlock = 7583802;
        address accountToProve = 0x456Cb24d30eaA6AfFC2A6924Dae0d2a0a8c99C73;

        _proveAccountWithAddressAtBlock(accountToProve, proveForBlock);

        uint256 expectedNonce = 0;
        uint256 savedNonce = uint256(factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.NONCE));
        assertEq(savedNonce, expectedNonce);

        uint256 expectedBalance = 0;
        uint256 savedBalance = uint256(factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.BALANCE));
        assertEq(savedBalance, expectedBalance);

        bytes32 expectedStorageRoot = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421; // EMPTY_TRIE_ROOT_HASH
        bytes32 accountStorageRoot = factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.STORAGE_ROOT);
        assertEq(accountStorageRoot, expectedStorageRoot);

        bytes32 expectedCodeHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // EMPTY_CODE_HASH
        bytes32 accountCodeHash = factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.CODE_HASH);
        assertEq(accountCodeHash, expectedCodeHash);
    }

    function test_proveStorage() public {
        uint256 proveForBlock = 7583802;
        address accountToProve = 0x7b2f05cE9aE365c3DBF30657e2DC6449989e83D6;
        bytes32 slotToProve = 0x0000000000000000000000000000000000000000000000000000000000000033;

        _proveAccountWithAddressAtBlock(accountToProve, proveForBlock);

        bytes memory storageProof = _getStorageProof(proveForBlock, accountToProve, slotToProve);
        factsRegistry.proveStorage(accountToProve, proveForBlock, slotToProve, storageProof);

        bytes32 expectedSlotValue = bytes32(uint256(uint160(0xeF7b1e0ddEA68Cad3d74fbB7A03E6Ccde3091286)));
        bytes32 actualSlotValue = factsRegistry.accountStorageSlotValues(accountToProve, proveForBlock, slotToProve);
        assertEq(actualSlotValue, expectedSlotValue);
    }

    function _proveAccountWithAddressAtBlock(address accountToProve, uint256 proveForBlock) internal {
        (bytes32[] memory peaks, bytes32[] memory mmrInclusionProof) = _peaksAndInclusionProofForBlock(proveForBlock);
        
        bytes memory rlpHeader = _getRlpBlockHeader(proveForBlock);
        bytes memory accountProof = _getAccountProof(proveForBlock, accountToProve);

        Types.BlockHeaderProof memory headerProof = Types.BlockHeaderProof({
            treeId: DEFAULT_TREE_ID,
            mmrTreeSize: 7,
            blockNumber: proveForBlock,
            blockProofLeafIndex: 1,
            mmrPeaks: peaks,
            mmrElementInclusionProof: mmrInclusionProof,
            provenBlockHeader: rlpHeader
        });
        factsRegistry.proveAccount(accountToProve, type(uint16).max, headerProof, accountProof);
    }

    function _getAccountProof(uint256 blockNumber, address account) internal returns(bytes memory) {
        string[] memory inputs = new string[](6);
        inputs[0] = "node";
        inputs[1] = "./helpers/state-proofs/fetch_state_proof.js";
        inputs[2] = blockNumber.toString();
        inputs[3] = uint256(uint160(account)).toHexString();
        inputs[4] = "0x0"; // storage key
        inputs[5] = "account"; // storage value
        bytes memory abiEncoded = vm.ffi(inputs);
        bytes memory accountProof = abi.decode(abiEncoded, (bytes));
        return accountProof;
    }

    function _getStorageProof(uint256 blockNumber, address account, bytes32 slot) internal returns(bytes memory) {
        string[] memory inputs = new string[](6);
        inputs[0] = "node";
        inputs[1] = "./helpers/state-proofs/fetch_state_proof.js";
        inputs[2] = blockNumber.toString();
        inputs[3] = uint256(uint160(account)).toHexString();
        inputs[4] = uint256(slot).toHexString();
        inputs[5] = "slot"; // storage value
        bytes memory abiEncoded = vm.ffi(inputs);
        bytes memory storageProof = abi.decode(abiEncoded, (bytes));
        return storageProof;
    }

    function _peaksAndInclusionProofForBlock(uint256 blockNumber) internal returns(bytes32[] memory peaks, bytes32[] memory inclusionProof) {
        require(blockNumber == 7583802, "ERR_TEST_MOCKED_HEADERS_PROCESSOR_ONLY_FOR_BLOCK_7583802");

        bytes[] memory headersBatch = new bytes[](4);
        headersBatch[0] = _getRlpBlockHeader(7583802);
        headersBatch[1] = _getRlpBlockHeader(7583801);
        headersBatch[2] = _getRlpBlockHeader(7583800);
        headersBatch[3] = _getRlpBlockHeader(7583801);

        uint256 provenLeafId = 1;

        string[] memory inputs = new string[](3 + headersBatch.length);
        inputs[0] = "node";
        inputs[1] = "./helpers/mmrs/get_peaks_and_inclusion_proof.js";
        inputs[2] = provenLeafId.toString(); // Generate proof for leaf with id
        for (uint256 i = 0; i < headersBatch.length; i++) {
            inputs[3 + i] = uint256(keccak256(headersBatch[i])).toHexString();
        }

        bytes memory abiEncoded = vm.ffi(inputs);
        (peaks, inclusionProof) = abi.decode(abiEncoded, (bytes32[], bytes32[]));
    }

    function _getRlpBlockHeader(uint256 blockNumber) internal returns(bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(inputs);
        return headerRlp;
    }
}
