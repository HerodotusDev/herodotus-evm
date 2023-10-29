// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {SecureMerkleTrie} from "@optimism/libraries/trie/SecureMerkleTrie.sol";
import {RLPReader} from "@optimism/libraries/rlp/RLPReader.sol";

import {HeadersProcessor} from "./HeadersProcessor.sol";

import {Types} from "../lib/Types.sol";
import {Bitmap16} from "../lib/Bitmap16.sol";
import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";


contract FactsRegistry {
    using EVMHeaderRLP for bytes;
    using Bitmap16 for uint16;

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    event AccountProven(address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash);
    event TransactionProven(uint256 blockNumber, bytes32 rlpEncodedTxIndex, bytes rlpEncodedTx);

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    HeadersProcessor public immutable headersProcessor;


    mapping(address => mapping(uint256 => mapping(Types.AccountFields => bytes32))) public accountField;
    // address => block number => slot => value
    mapping(address => mapping(uint256 => mapping(bytes32 => bytes32))) public accountStorageSlotValues;

    constructor(address _headersProcessor) {
        headersProcessor = HeadersProcessor(_headersProcessor);
    }

    function proveAccount(
        address account,
        uint16 accountFieldsToSave,
        Types.BlockHeaderProof calldata headerProof,
        Types.AccountTrieProof calldata accountTrieProof
    ) external {
        // Ensure provided header is a valid one by making sure it is committed in the HeadersStore MMR
        _verifyAccumulatedHeaderProof(headerProof);

        // Verify the account state proof
        bytes32 stateRoot = headerProof.provenBlockHeader.getStateRoot();
        bool isAccountProofValid = SecureMerkleTrie.verifyInclusionProof(
            abi.encode(account),
            accountTrieProof.accountRLP,
            accountTrieProof.trieProof,
            stateRoot
        );
        require(isAccountProofValid, "ERR_INVALID_ACCOUNT_PROOF");
        RLPReader.RLPItem[] memory accountFields = accountTrieProof.accountRLP.toRLPItem().readList();

        // Decode the account fields
        (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) = _decodeAccountFields(accountFields);

        // Save the desired account properties to the storage
        if (accountFieldsToSave.readBitAtIndexFromRight(0)) {
            accountField[account][headerProof.blockNumber][Types.AccountFields.NONCE] = bytes32(nonce);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(1)) {
            accountField[account][headerProof.blockNumber][Types.AccountFields.BALANCE] = bytes32(accountBalance);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(2)) {
            accountField[account][headerProof.blockNumber][Types.AccountFields.CODE_HASH] = codeHash;
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(3)) {
            accountField[account][headerProof.blockNumber][Types.AccountFields.STORAGE_ROOT] = storageRoot;
        }

        emit AccountProven(
            account,
            headerProof.blockNumber,
            nonce,
            accountBalance,
            codeHash,
            storageRoot
        );        
    }

    function proveStorage(address account, uint256 blockNumber, bytes32 slot, Types.StorageSlotTrieProof calldata storageSlotTrieProof) external {
        bytes32 storageRoot = accountField[account][blockNumber][Types.AccountFields.STORAGE_ROOT];
        require(storageRoot != bytes32(0), "ERR_EMPTY_STORAGE_ROOT");

        bool isStorageProofValid = SecureMerkleTrie.verifyInclusionProof(
            abi.encode(slot),
            storageSlotTrieProof.slotValue,
            storageSlotTrieProof.trieProof,
            storageRoot
        );
        require(isStorageProofValid, "ERR_INVALID_STORAGE_PROOF");

        bytes memory slotValueBytes = storageSlotTrieProof.slotValue;
        bytes32 slotValue;
        assembly {
            slotValue := mload(add(slotValueBytes, 32))
        }

        accountStorageSlotValues[account][blockNumber][slot] = slotValue;
    }

    function verifyAccount() external view {
        // TODO
    }

    function verifyStorage() external view {
        // TODO
    }

    function _verifyAccumulatedHeaderProof(
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

    function _decodeAccountFields(RLPReader.RLPItem[] memory accountFields) internal pure returns(uint256, uint256, bytes32, bytes32) {
        bytes memory nonceBytes = accountFields[ACCOUNT_NONCE_INDEX].readBytes();
        uint256 nonce;
        assembly {
            nonce := mload(add(nonceBytes, 32))
        }

        bytes memory balanceBytes = accountFields[ACCOUNT_BALANCE_INDEX].readBytes();
        uint256 accountBalance;
        assembly {
            accountBalance := mload(add(balanceBytes, 32))
        }

        bytes memory codeHashBytes = accountFields[ACCOUNT_CODE_HASH_INDEX].readBytes();
        bytes32 codeHash;
        assembly {
            codeHash := mload(add(codeHashBytes, 32))
        }

        bytes memory storageRootBytes = accountFields[ACCOUNT_STORAGE_ROOT_INDEX].readBytes();
        bytes32 storageRoot;
        assembly {
            storageRoot := mload(add(storageRootBytes, 32))
        }

        return (nonce, accountBalance, codeHash, storageRoot);
    }
}
