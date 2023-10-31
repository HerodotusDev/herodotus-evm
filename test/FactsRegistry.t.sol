// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FactsRegistry} from "../src/core/FactsRegistry.sol";
import {Types} from "../src/lib/Types.sol";

import "forge-std/console.sol";

uint256 constant DEFAULT_TREE_ID = 0;

contract MockedHeadersProcessor {
    bytes32 constant ROOT_OF_MMR_CONTAINING_BLOCK_7583802_AT_INDEX_1 = 0x2e60617b4d3dfe11836dff47277aec8eb997a319003d4ba84b9c974b3bdac20b;
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

    function test_proveAccount() public {
        (bytes32[] memory peaks, bytes32[] memory mmrInclusionProof) = _peaksAndInclusionProofForBlock7583802();
        
        address accountToProve = 0x7b2f05cE9aE365c3DBF30657e2DC6449989e83D6;
        uint256 proveForBlock = 7583802;
        
        bytes memory rlpHeader = _getRlpBlockHeader(proveForBlock);
        bytes memory accountProof = _getAccountProof(proveForBlock, accountToProve);

        // TODO something silly is happening here
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

        uint256 savedNonce = uint256(factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.NONCE));
        // assertEq(savedNonce, 1);

        bytes32 accountStorageRoot = factsRegistry.accountField(accountToProve, proveForBlock, Types.AccountFields.STORAGE_ROOT);
        assertEq(accountStorageRoot, 0x1c35dfde2b62d99d3a74fda76446b60962c4656814bdd7815eb6e5b8be1e7185);
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

    function _peaksAndInclusionProofForBlock7583802() internal returns(bytes32[] memory peaks, bytes32[] memory inclusionProof) {
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
