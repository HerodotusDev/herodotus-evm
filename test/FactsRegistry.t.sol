// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FactsRegistry} from "src/core/FactsRegistry.sol";
import {Types} from "src/lib/Types.sol";

uint256 constant DEFAULT_TREE_ID = 0;

contract MockedHeadersProcessor {
    bytes32 constant ROOT_OF_MMR_CONTAINING_BLOCK_7583802_AT_INDEX_1 = 0x7925fc646e7ff14336b092e12adf5b66e8da65a06b14c486c231fcb92ca6c74c;
    uint256 constant SIZE_OF_MMR_CONTAINING_BLOCK_7583802_AT_INDEX_1 = 7;

    function getMMRRoot(uint256 mmrId, uint256 mmrSize) external pure returns (bytes32) {
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

    function _getAccountProof(uint256 blockNumber, address account) internal returns (bytes memory) {
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

    function _getStorageProof(uint256 blockNumber, address account, bytes32 slot) internal returns (bytes memory) {
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

    function _peaksAndInclusionProofForBlock(uint256 blockNumber) internal returns (bytes32[] memory peaks, bytes32[] memory inclusionProof) {
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
        (, peaks, inclusionProof) = abi.decode(abiEncoded, (bytes32, bytes32[], bytes32[]));
    }

    function _getRlpBlockHeader(uint256 blockNumber) internal returns (bytes memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "node";
        inputs[1] = "./helpers/fetch_header_rlp.js";
        inputs[2] = blockNumber.toString();
        bytes memory headerRlp = vm.ffi(inputs);
        return headerRlp;
    }
}

contract MockedHeadersProcessorSepolia {
    bytes32 constant MOCKED_ROOT = 0x62d451ed3f131fa253957db4501b0f4b6eb3f29c706663be3f75a35b7b372a38;
    uint256 constant MOCKED_MMR_SIZE = 13024091;
    uint256 constant MOCKED_TREE_ID = 27;

    function getMMRRoot(uint256 mmrId, uint256 mmrSize) external pure returns (bytes32) {
        require(mmrId == MOCKED_TREE_ID, "ERR_INVALID_MMR_ID");
        require(mmrSize == MOCKED_MMR_SIZE, "ERR_INVALID_MMR_SIZE");
        return MOCKED_ROOT;
    }
}


contract FactsRegistry_Test_Sepolia is Test {
    FactsRegistry private factsRegistry;

    constructor() {
        MockedHeadersProcessorSepolia mockedHeadersProcessor = new MockedHeadersProcessorSepolia();
        factsRegistry = new FactsRegistry(address(mockedHeadersProcessor));
    }

    function test_proveReceipt() public {
        uint256 proveForBlock = 6141490;
        uint256 receiptIndex = 23;

        bytes memory rlpHeader = _getRlpBlockHeader(proveForBlock);
        (bytes32[] memory peaks, bytes32[] memory mmrInclusionProof) = _peaksAndInclusionProofForBlock(proveForBlock);
        Types.BlockHeaderProof memory headerProof = Types.BlockHeaderProof({
            treeId: 27,
            mmrTreeSize: 13024091,
            blockNumber: proveForBlock,
            blockProofLeafIndex: 12635058,
            mmrPeaks: peaks,
            mmrElementInclusionProof: mmrInclusionProof,
            provenBlockHeader: rlpHeader
        });
        bytes memory receiptProof = _getReceiptProof(proveForBlock, receiptIndex);

    }

    function _getReceiptProof(uint256 blockNumber, uint256 receiptIndex) internal returns (bytes memory) {
        return bytes("");
    }

    function _getRlpBlockHeader(uint256 blockNumber) internal returns (bytes memory) {
        require(blockNumber == 6141490, "ERR_TEST_MOCKED_HEADERS_PROCESSOR_ONLY_FOR_BLOCK_6141490");
        return hex"f9024ba0631f6dee622d972cbf5913b5b2eae47131bd7c970e6454aa618905a9b70cb379a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347943826539cbd8d68dcf119e80b994557b4278cec9fa01eb49e5c7d22bbb689a59f43a9ef1ffc24f5f04ea3fef1c229f76529f5d3d49da0311be26e5f8baeb5c1c82bff16e1a5494e414b1a9d396d4db00212e69ab60e0aa07659e429f9a6383bea1fe1651f27d41f6a7fb46a7a5d32260d819b64632d1345b90100f5c4412ea40af7a3ec9d5b933a5eb3e4cefb73aad2e80b55bfd12e37e7fadd04252c444a4f82a4a1375b592d2735aef49478dfc29a2da331b6769e3976f407a915fee2e0d8a7e107d2f7ea1afefb3756866d78d97faeed61a8219b7605e4758b65a3a510ab3b66dc72bba79539988dbcff2d1ffeddfc10fd3a8bc2928adfa677ffe1195f6b79e815fce437c9a739426f49e96f683e54f46e9845725dedc0577feef9f4bbfd36c0af8a5231cad9ef58cf88edcd963e63791adc9782e978583d33f1fbbd2ff2fd0b9bbbc33bfa39e683e9c2373ec2446fce85e2ac59ebdde5e014b5f6067fbe6610afb74c58c3af89dd5d8a7afbf38cfa49e1ea39fe535a0e5bde80835db6328401c9c3808401c9ba65846673047c80a0483b760e45bc4b71a6263a8320c649d58353aedf50ddee460dae0677fe9f603d880000000000000000842f61185ea0f3aac3e72ed9278dd149f5e709fad5d974620955412457e2a8c0b45dd4d3faaf830a000083080000a04117213c99012c32edcac0a99b6c98c4fc1f085407ee5c06e60634e79545f418";
    }

    function _peaksAndInclusionProofForBlock(uint256 blockNumber) internal returns (bytes32[] memory, bytes32[] memory) {
        require(blockNumber == 6141490, "ERR_TEST_MOCKED_HEADERS_PROCESSOR_ONLY_FOR_BLOCK_6141490");

        // Populate peaks
        bytes32[] memory peaks = new bytes32[](13);
        peaks[0] = 0xea94b197307128f1e18f9f3186a6452bd201b86f484f80cc3b2cbfb0b646c577;
        peaks[1] = 0xff430ddf60e969c483750fd56caee265cab4037f437d4a0a45eee230088e9092;
        peaks[2] = 0x8735438529236334bc5b13c0bb8ba6ad62f1b0e7f821a739fcdbd7903d618d6a;
        peaks[3] = 0xc86310b6895e77987c3e0afa79b0e2fac4538405a5e3ab276c915cdb4e74b4b9;
        peaks[4] = 0x9dd90ca28eac4c7e903923164d9ca4e4227fb0c400ec1f9da20fa0ef33f438be;
        peaks[5] = 0x73d7ed3f6cf4713925838f61e8debebbee3d33652d684488387d05712837af1e;
        peaks[6] = 0x8f570e28c7fa0d9aef96bc80e1985696094fa132b47417b67429b37fb3413469;
        peaks[7] = 0x5e5ad2c6f4e13950a0ddd7e0c803aa24cd968c59d104f6ac5a46631c63896273;
        peaks[8] = 0x9e45d7d4fa8c5711c2df9636f3493ab31e1a12e463a0eec4798aa163d4d9a2a2;
        peaks[9] = 0x481b6377529be8836be09c47917289c5218b710e2d2f186c3b96f7d404a02312;
        peaks[10] = 0xf864d07f7cf26b072aa30e1223cf16f338d499fe83935836ff565c3cf9e42530;
        peaks[11] = 0x6fdbe7ef87553b453ef0c66322a33575f1e92b00d2abca122f9d9caeddca03b7;
        peaks[12] = 0x45da6302e5933720e03c6f851000ac3605ca863c54839c265eadc252bf7c4764;

        // Populate inclusion proof
        bytes32[] memory inclusionProof = new bytes32[](17);
        inclusionProof[0] = 0x7267498ed198e44b629e5d7bcfdadaf16c0a2568d2b1dc112fa2767bad250cef;
        inclusionProof[1] = 0x8943ada2b8a5bcf47bab685fc97f6478eb01352887241df2ee6a47933ac54540;
        inclusionProof[2] = 0xa45e7796e62be5cc8a9dca0fbeae5f30fdbbbd9f7ac931c4ed82497565e253ca;
        inclusionProof[3] = 0x43ebc27cd1d7d263b5e819a850fa2dbffe4770046b8150fe122eb14624f583fb;
        inclusionProof[4] = 0xb6d94f8f206a8ea080693ee0d92479af8e64f81fe97f3b0b6ea26a94fd0ddee5;
        inclusionProof[5] = 0x5fa7d0c889154c27080a1bbd468e06d8fe66818fecc34b122334254668de10f3;
        inclusionProof[6] = 0x3d601177d51293fd1eb204786549cbf3411b4fa8cdc616286938a90e7ac1cbf6;
        inclusionProof[7] = 0x49d5438538d461e6010230d8e0b86e7cd1b6cf6bc128c3403b6e71889978d335;
        inclusionProof[8] = 0xb9c6adb177e1c7cde9bc12f21fd7df4a4e08494d2797f5958fd0dd85761a0abd;
        inclusionProof[9] = 0xbca54e1525b3ba2084c54ae585c708e1babd62dd13fbc72caf3ff3fb58cec73b;
        inclusionProof[10] = 0x88718ad5c7d3099ebbcc986bd2eab5ac98dcc776e354e82dbdf25551230f8789;
        inclusionProof[11] = 0xb70d00f399d41cebf2ff52ed63e57ff48471121faf48713a5be898edaffdcc20;
        inclusionProof[12] = 0xd8960eaf6987c95f3919ff5101307b7858b73756a94f6b815fab82f0dc08468b;
        inclusionProof[13] = 0x67db40be642d7e791e992c8e79ba76dc0216b2e2d92a111eb77e97badcbd5fd9;
        inclusionProof[14] = 0xe6844c0d47a72488e1f6c3b7bf983ffa65404588b3ded0634049193fc3e2ec5b;
        inclusionProof[15] = 0xccf1f92a8b184b5b6c3907b35c237b1e3aab4485f4a8990912cfc25f32214acc;
        inclusionProof[16] = 0xba786a1af8828b5001d1fe93241e96c6319815a05f9d6acfa6a6d36081f88d00;

        return (peaks, inclusionProof);
    }

}

