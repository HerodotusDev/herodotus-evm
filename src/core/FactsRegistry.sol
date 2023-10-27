// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

import {HeadersProcessor} from "./HeadersProcessor.sol";

import {Types} from "../lib/Types.sol";
import {RLP} from "../lib/RLP.sol";
import {TrieProofs} from "../lib/TrieProofs.sol";
import {Bitmap16} from "../lib/Bitmap16.sol";
import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";
import {FixedSizeMerkleTree} from "../lib/FixedSizeMerkleTree.sol";



contract FactsRegistry {
    using EVMHeaderRLP for bytes;
    using TrieProofs for bytes;
    using RLP for RLP.RLPItem;
    using RLP for bytes;
    using Bitmap16 for uint16;

    event AccountProven(address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash);
    event TransactionProven(uint256 blockNumber, bytes32 rlpEncodedTxIndex, bytes rlpEncodedTx);

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    HeadersProcessor public immutable headersProcessor;

    mapping(address => mapping(uint256 => uint256)) public accountNonces;
    mapping(address => mapping(uint256 => uint256)) public accountBalances;
    mapping(address => mapping(uint256 => bytes32)) public accountCodeHashes;
    mapping(address => mapping(uint256 => bytes32)) public accountStorageHashes;
    // address => block number => slot => value
    mapping(address => mapping(uint256 => mapping(bytes32 => bytes32))) public accountStorageSlotValues;

    // transactionStatus mapping
    mapping(uint256 => mapping(bytes32 => uint256)) public transactionStatuses;
    // cumulativeGasUsed mapping
    mapping(uint256 => mapping(bytes32 => uint256)) public transactionsCumulativeGasUsed;
    // logsBloom mapping
    mapping(uint256 => mapping(bytes32 => bytes)) public transactionsLogsBlooms;
    // logs mapping
    mapping(uint256 => mapping(bytes32 => bytes)) public transactionsLogs;

    constructor(address _headersProcessor) {
        headersProcessor = HeadersProcessor(_headersProcessor);
    }

    function _verifyMmrProof(
        Types.BlockHeaderProof memory proof
    ) internal view {
        bytes32 mmrRoot = headersProcessor.getMMRRoot(proof.treeId, proof.mmrTreeSize);
        require(mmrRoot != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        bytes32 blockHeaderHash = keccak256(proof.provenBlockHeader);

        StatelessMmr.verifyProof(
            proof.blockProofLeafIndex,
            blockHeaderHash,
            proof.mmrElementInclusionProof,
            proof.mmrPeaks,
            proof.mmrTreeSize,
            mmrRoot
        );

        uint256 actualBlockNumber = proof.provenBlockHeader.getBlockNumber();
        require(actualBlockNumber == proof.blockNumber, "ERR_INVALID_BLOCK_NUMBER");
    }

    function proveAccount(
        address account,
        uint16 accountFieldsToSave,
        Types.BlockHeaderProof calldata headerProof,
        bytes calldata mptProof
    ) external {
        // Ensure provided header is a valid one by making sure it is committed in the HeadersStore MMR
        _verifyMmrProof(headerProof);

        // Verify the account state proof
        bytes32 stateRoot = headerProof.provenBlockHeader.getStateRoot();
        bytes32 proofPath = keccak256(abi.encodePacked(account));
        RLP.RLPItem[] memory accountFields = mptProof.verify(stateRoot, proofPath).toRLPItem().toList();

        // Save the desired account properties to the storage
        if (accountFieldsToSave.readBitAtIndexFromRight(0)) {
            accountNonces[account][headerProof.blockNumber] = accountFields[ACCOUNT_NONCE_INDEX].toUint();
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(1)) {
            accountBalances[account][headerProof.blockNumber] = accountFields[ACCOUNT_BALANCE_INDEX].toUint();
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(2)) {
            accountCodeHashes[account][headerProof.blockNumber] = bytes32(accountFields[ACCOUNT_CODE_HASH_INDEX].toUint());
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(3)) {
            accountStorageHashes[account][headerProof.blockNumber] = bytes32(accountFields[ACCOUNT_STORAGE_ROOT_INDEX].toUint());
        }

        emit AccountProven(
            account,
            headerProof.blockNumber,
            accountNonces[account][headerProof.blockNumber],
            accountBalances[account][headerProof.blockNumber],
            accountCodeHashes[account][headerProof.blockNumber],
            accountStorageHashes[account][headerProof.blockNumber]
        );        
    }

    function proveStorage(address account, uint256 blockNumber, bytes32 slot, bytes memory storageProof) external {
        bytes32 root = accountStorageHashes[account][blockNumber];
        require(root != bytes32(0), "ERR_EMPTY_STORAGE_ROOT");
        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        bytes32 slotValue = bytes32(storageProof.verify(root, proofPath).toRLPItem().toUint());
        accountStorageSlotValues[account][blockNumber][slot] = slotValue;
    }

    function removeFirstNibble(bytes memory input) internal pure returns (bytes memory) {
        require(input.length > 0, "Input cannot be empty");

        bytes memory output = new bytes(input.length - 1);
        for (uint256 i = 1; i < input.length; i++) {
            output[i - 1] = input[i];
        }
        return output;
    }

    // function checkTransactionReceipt(
    //     uint256 treeId,
    //     uint256 blockNumber,
    //     bytes32 rlpEncodedTxIndex,
    //     uint256 blockProofLeafIndex,
    //     bytes32 blockProofLeafValue,
    //     uint256 mmrTreeSize,
    //     bytes32[] calldata blockProof,
    //     bytes32[] calldata mmrPeaks,
    //     bytes calldata headerSerialized,
    //     bytes calldata proof
    // ) public view returns (bytes memory receiptRlp) {
    //     _verifyMmrProof(treeId, blockNumber, blockProofLeafIndex, blockProofLeafValue, mmrTreeSize, blockProof, mmrPeaks, headerSerialized);

    //     bytes32 receiptsRoot = headerSerialized.getReceiptsRoot();

    //     receiptRlp = proof.verify(receiptsRoot, rlpEncodedTxIndex);
    // }

    // function proveTransactionReceipt(
    //     uint256 treeId,
    //     uint16 paramsBitmap,
    //     uint256 blockNumber,
    //     bytes32 rlpEncodedTxIndex,
    //     uint256 blockProofLeafIndex,
    //     bytes32 blockProofLeafValue,
    //     uint256 mmrTreeSize,
    //     bytes32[] calldata blockProof,
    //     bytes32[] calldata mmrPeaks,
    //     bytes calldata headerSerialized,
    //     bytes calldata proof
    // ) external returns (bytes memory receiptRlp) {
    //     receiptRlp = checkTransactionReceipt(
    //         treeId,
    //         blockNumber,
    //         rlpEncodedTxIndex,
    //         blockProofLeafIndex,
    //         blockProofLeafValue,
    //         mmrTreeSize,
    //         blockProof,
    //         mmrPeaks,
    //         headerSerialized,
    //         proof
    //     );

    //     if (receiptRlp[0] == 0x02 || receiptRlp[0] == 0x01) {
    //         receiptRlp = removeFirstNibble(receiptRlp);
    //     }

    //     RLP.RLPItem[] memory receiptItems = receiptRlp.toRLPItem().toList();
    //     require(receiptItems.length == 4, "ERR_INVALID_RECEIPT_RLP");

    //     // Store transaction status
    //     if (paramsBitmap.readBitAtIndexFromRight(0)) {
    //         transactionStatuses[blockNumber][rlpEncodedTxIndex] = receiptItems[0].toUint();
    //     }

    //     // Store cumulative gas used
    //     if (paramsBitmap.readBitAtIndexFromRight(1)) {
    //         transactionsCumulativeGasUsed[blockNumber][rlpEncodedTxIndex] = receiptItems[1].toUint();
    //     }

    //     // Store logs bloom
    //     if (paramsBitmap.readBitAtIndexFromRight(2)) {
    //         transactionsLogsBlooms[blockNumber][rlpEncodedTxIndex] = receiptItems[2].toBytes();
    //     }

    //     // Store logs
    //     if (paramsBitmap.readBitAtIndexFromRight(3)) {
    //         transactionsLogs[blockNumber][rlpEncodedTxIndex] = receiptItems[3].toRLPBytes();
    //     }

    //     emit TransactionProven(blockNumber, rlpEncodedTxIndex, receiptRlp);
    // }
}
