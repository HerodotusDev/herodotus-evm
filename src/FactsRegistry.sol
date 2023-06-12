// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {IFactsRegistry} from "./interfaces/IFactsRegistry.sol";

import {RLP} from "./lib/RLP.sol";
import {TrieProofs} from "./lib/TrieProofs.sol";
import {Bitmap16} from "./lib/Bitmap16.sol";
import {EVMHeaderRLP} from "./lib/EVMHeaderRLP.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

contract FactsRegistry is IFactsRegistry {
    using EVMHeaderRLP for bytes;
    using TrieProofs for bytes;
    using RLP for RLP.RLPItem;
    using RLP for bytes;
    using Bitmap16 for uint16;

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    IHeadersProcessor public immutable headersProcessor;

    mapping(address => mapping(uint256 => uint256)) public accountNonces;
    mapping(address => mapping(uint256 => uint256)) public accountBalances;
    mapping(address => mapping(uint256 => bytes32)) public accountCodeHashes;
    mapping(address => mapping(uint256 => bytes32)) public accountStorageHashes;

    event AccountProven(address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash);

    // transactionStatus mapping
    mapping(uint256 => mapping(bytes32 => uint256)) public transactionStatuses;
    // cumulativeGasUsed mapping
    mapping(uint256 => mapping(bytes32 => uint256)) public transactionsCumulativeGasUsed;
    // logsBloom mapping
    mapping(uint256 => mapping(bytes32 => bytes)) public transactionsLogsBlooms;
    // logs mapping
    mapping(uint256 => mapping(bytes32 => bytes)) public transactionsLogs;

    event TransactionProven(uint256 blockNumber, bytes32 rlpEncodedTxIndex, bytes rlpEncodedTx);

    constructor(IHeadersProcessor _headersProcessor) {
        headersProcessor = _headersProcessor;
    }

    function verifyMmrProof(
        uint256 treeId,
        uint256 blockNumber,
        uint256 blockProofLeafIndex,
        bytes32 blockProofLeafValue,
        uint256 mmrTreeSize,
        bytes32[] calldata blockProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata headerSerialized
    ) internal view {
        bytes32 mmrRoot = headersProcessor.mmrsTreeSizeToRoot(treeId, mmrTreeSize);
        require(mmrRoot != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        require(keccak256(headerSerialized) == blockProofLeafValue, "ERR_INVALID_PROOF_LEAF");
        StatelessMmr.verifyProof(blockProofLeafIndex, blockProofLeafValue, blockProof, mmrPeaks, mmrTreeSize, mmrRoot);

        uint256 actualBlockNumber = headerSerialized.getBlockNumber();
        require(actualBlockNumber == blockNumber, "ERR_INVALID_BLOCK_NUMBER");
    }

    function proveAccount(
        uint256 treeId,
        uint16 paramsBitmap,
        uint256 blockNumber,
        address account,
        uint256 blockProofLeafIndex,
        bytes32 blockProofLeafValue,
        uint256 mmrTreeSize,
        bytes32[] calldata blockProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata headerSerialized,
        bytes calldata proof
    ) external {
        verifyMmrProof(treeId, blockNumber, blockProofLeafIndex, blockProofLeafValue, mmrTreeSize, blockProof, mmrPeaks, headerSerialized);

        bytes32 stateRoot = headerSerialized.getStateRoot();
        bytes32 proofPath = keccak256(abi.encodePacked(account));
        bytes memory accountRLP = proof.verify(stateRoot, proofPath);

        bytes32 storageHash = EMPTY_TRIE_ROOT_HASH;
        bytes32 codeHash = EMPTY_CODE_HASH;
        uint256 nonce;
        uint256 balance;

        if (accountRLP.length > 0) {
            RLP.RLPItem[] memory accountItems = accountRLP.toRLPItem().toList();

            if (paramsBitmap.readBitAtIndexFromRight(0)) {
                storageHash = bytes32(accountItems[ACCOUNT_STORAGE_ROOT_INDEX].toUint());
            }

            if (paramsBitmap.readBitAtIndexFromRight(1)) {
                codeHash = bytes32(accountItems[ACCOUNT_CODE_HASH_INDEX].toUint());
            }

            if (paramsBitmap.readBitAtIndexFromRight(2)) {
                nonce = accountItems[ACCOUNT_NONCE_INDEX].toUint();
            }

            if (paramsBitmap.readBitAtIndexFromRight(3)) {
                balance = accountItems[ACCOUNT_BALANCE_INDEX].toUint();
            }
            emit AccountProven(account, blockNumber, nonce, balance, codeHash, storageHash);
        }

        // SAVE STORAGE_HASH
        if (paramsBitmap.readBitAtIndexFromRight(0)) {
            accountStorageHashes[account][blockNumber] = storageHash;
        }

        // SAVE CODE_HASH
        if (paramsBitmap.readBitAtIndexFromRight(1)) {
            accountCodeHashes[account][blockNumber] = codeHash;
        }

        // SAVE NONCE
        if (paramsBitmap.readBitAtIndexFromRight(2)) {
            accountNonces[account][blockNumber] = nonce;
        }

        // SAVE BALANCE
        if (paramsBitmap.readBitAtIndexFromRight(3)) {
            accountBalances[account][blockNumber] = balance;
        }
    }

    function proveStorage(address account, uint256 blockNumber, bytes32 slot, bytes memory storageProof) external view returns (bytes32) {
        bytes32 root = accountStorageHashes[account][blockNumber];
        require(root != bytes32(0), "ERR_EMPTY_STORAGE_ROOT");
        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        return bytes32(storageProof.verify(root, proofPath).toRLPItem().toUint());
    }

    function removeFirstNibble(bytes memory input) internal pure returns (bytes memory) {
        require(input.length > 0, "Input cannot be empty");

        bytes memory output = new bytes(input.length - 1);
        for (uint256 i = 1; i < input.length; i++) {
            output[i - 1] = input[i];
        }
        return output;
    }

    function checkTransactionReceipt(
        uint256 treeId,
        uint256 blockNumber,
        bytes32 rlpEncodedTxIndex,
        uint256 blockProofLeafIndex,
        bytes32 blockProofLeafValue,
        uint256 mmrTreeSize,
        bytes32[] calldata blockProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata headerSerialized,
        bytes calldata proof
    ) public view returns (bytes memory receiptRlp) {
        verifyMmrProof(treeId, blockNumber, blockProofLeafIndex, blockProofLeafValue, mmrTreeSize, blockProof, mmrPeaks, headerSerialized);

        bytes32 receiptsRoot = headerSerialized.getReceiptsRoot();

        receiptRlp = proof.verify(receiptsRoot, rlpEncodedTxIndex);
    }

    function proveTransactionReceipt(
        uint256 treeId,
        uint16 paramsBitmap,
        uint256 blockNumber,
        bytes32 rlpEncodedTxIndex,
        uint256 blockProofLeafIndex,
        bytes32 blockProofLeafValue,
        uint256 mmrTreeSize,
        bytes32[] calldata blockProof,
        bytes32[] calldata mmrPeaks,
        bytes calldata headerSerialized,
        bytes calldata proof
    ) external returns (bytes memory receiptRlp) {
        receiptRlp = checkTransactionReceipt(
            treeId,
            blockNumber,
            rlpEncodedTxIndex,
            blockProofLeafIndex,
            blockProofLeafValue,
            mmrTreeSize,
            blockProof,
            mmrPeaks,
            headerSerialized,
            proof
        );

        if (receiptRlp[0] == 0x02) {
            receiptRlp = removeFirstNibble(receiptRlp);
        }

        RLP.RLPItem[] memory receiptItems = receiptRlp.toRLPItem().toList();
        require(receiptItems.length == 4, "ERR_INVALID_RECEIPT_RLP");

        // Store transaction status
        if (paramsBitmap.readBitAtIndexFromRight(0)) {
            transactionStatuses[blockNumber][rlpEncodedTxIndex] = receiptItems[0].toUint();
        }

        // Store cumulative gas used
        if (paramsBitmap.readBitAtIndexFromRight(1)) {
            transactionsCumulativeGasUsed[blockNumber][rlpEncodedTxIndex] = receiptItems[1].toUint();
        }

        // Store logs bloom
        if (paramsBitmap.readBitAtIndexFromRight(2)) {
            transactionsLogsBlooms[blockNumber][rlpEncodedTxIndex] = receiptItems[2].toBytes();
        }

        // Store logs
        if (paramsBitmap.readBitAtIndexFromRight(3)) {
            transactionsLogs[blockNumber][rlpEncodedTxIndex] = receiptItems[3].toRLPBytes();
        }

        emit TransactionProven(blockNumber, rlpEncodedTxIndex, receiptRlp);
    }
}
