// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {Lib_SecureMerkleTrie as SecureMerkleTrie} from "@optimism/libraries/trie/Lib_SecureMerkleTrie.sol";
import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";

import {HeadersStore} from "./HeadersStore.sol";

import {Types} from "../lib/Types.sol";
import {Bitmap16} from "../lib/Bitmap16.sol";
import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";
import {NullableStorageSlot} from "../lib/NullableStorageSlot.sol";

contract FactsRegistry {
    using EVMHeaderRLP for bytes;
    using Bitmap16 for uint16;

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    event AccountProven(
        address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash
    );
    event StorageSlotProven(address account, uint256 blockNumber, bytes32 slot, bytes32 slotValue);

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    HeadersStore public immutable headersStore;

    mapping(address => mapping(uint256 => mapping(Types.AccountFields => bytes32))) internal _accountField;
    // address => block number => slot => value
    mapping(address => mapping(uint256 => mapping(bytes32 => bytes32))) internal _accountStorageSlotValues;

    constructor(address _headersStore) {
        headersStore = HeadersStore(_headersStore);
    }

    function proveAccount(
        address account,
        uint16 accountFieldsToSave,
        Types.BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) external {
        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) =
            verifyAccount(account, headerProof, accountTrieProof);

        // Save the desired account properties to the storage
        if (accountFieldsToSave.readBitAtIndexFromRight(0)) {
            uint256 nonceNullable = NullableStorageSlot.toNullable(nonce);
            _accountField[account][headerProof.blockNumber][Types.AccountFields.NONCE] = bytes32(nonceNullable);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(1)) {
            uint256 accountBalanceNullable = NullableStorageSlot.toNullable(accountBalance);
            _accountField[account][headerProof.blockNumber][Types.AccountFields.BALANCE] =
                bytes32(accountBalanceNullable);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(2)) {
            uint256 codeHashNullable = NullableStorageSlot.toNullable(uint256(codeHash));
            _accountField[account][headerProof.blockNumber][Types.AccountFields.CODE_HASH] = bytes32(codeHashNullable);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(3)) {
            uint256 storageRootNullable = NullableStorageSlot.toNullable(uint256(storageRoot));
            _accountField[account][headerProof.blockNumber][Types.AccountFields.STORAGE_ROOT] =
                bytes32(storageRootNullable);
        }

        emit AccountProven(account, headerProof.blockNumber, nonce, accountBalance, codeHash, storageRoot);
    }

    function proveStorage(address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof)
        external
    {
        // Verify the proof and decode the slot value
        uint256 slotValueNullable =
            NullableStorageSlot.toNullable(uint256(verifyStorage(account, blockNumber, slot, storageSlotTrieProof)));
        _accountStorageSlotValues[account][blockNumber][slot] = bytes32(slotValueNullable);
        emit StorageSlotProven(account, blockNumber, slot, bytes32(NullableStorageSlot.fromNullable(slotValueNullable)));
    }

    function verifyAccount(
        address account,
        Types.BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) public view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) {
        // Ensure provided header is a valid one by making sure it is committed in the HeadersStore MMR
        _verifyAccumulatedHeaderProof(headerProof);

        // Verify the account state proof
        bytes32 stateRoot = headerProof.provenBlockHeader.getStateRoot();

        (bool doesAccountExist, bytes memory accountRLP) =
            SecureMerkleTrie.get(abi.encodePacked(account), accountTrieProof, stateRoot);
        // Decode the account fields
        (nonce, accountBalance, storageRoot, codeHash) = _decodeAccountFields(doesAccountExist, accountRLP);
    }

    function verifyStorage(address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof)
        public
        view
        returns (bytes32 slotValue)
    {
        bytes32 storageRootRaw = _accountField[account][blockNumber][Types.AccountFields.STORAGE_ROOT];
        // Convert from nullable
        bytes32 storageRoot = bytes32(NullableStorageSlot.fromNullable(uint256(storageRootRaw)));

        (, bytes memory slotValueRLP) = SecureMerkleTrie.get(abi.encode(slot), storageSlotTrieProof, storageRoot);

        slotValue = slotValueRLP.toRLPItem().readBytes32();
    }

    function accountField(address account, uint256 blockNumber, Types.AccountFields field)
        external
        view
        returns (bytes32)
    {
        bytes32 valueRaw = _accountField[account][blockNumber][field];
        // If value is null revert
        if (NullableStorageSlot.isNull(uint256(valueRaw))) {
            revert("ERR_VALUE_IS_NULL");
        }
        return bytes32(NullableStorageSlot.fromNullable(uint256(valueRaw)));
    }

    function accountStorageSlotValues(address account, uint256 blockNumber, bytes32 slot)
        external
        view
        returns (bytes32)
    {
        bytes32 valueRaw = _accountStorageSlotValues[account][blockNumber][slot];
        // If value is null revert
        if (NullableStorageSlot.isNull(uint256(valueRaw))) {
            revert("ERR_VALUE_IS_NULL");
        }
        return bytes32(NullableStorageSlot.fromNullable(uint256(valueRaw)));
    }

    function _verifyAccumulatedHeaderProof(Types.BlockHeaderProof memory proof) internal view {
        bytes32 mmrRoot = headersStore.getMMRRoot(proof.treeId, proof.mmrTreeSize);
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

    function _decodeAccountFields(bool doesAccountExist, bytes memory accountRLP)
        internal
        pure
        returns (uint256 nonce, uint256 balance, bytes32 storageRoot, bytes32 codeHash)
    {
        if (!doesAccountExist) {
            return (0, 0, EMPTY_TRIE_ROOT_HASH, EMPTY_CODE_HASH);
        }

        RLPReader.RLPItem[] memory accountFields = accountRLP.toRLPItem().readList();

        nonce = accountFields[ACCOUNT_NONCE_INDEX].readUint256();
        balance = accountFields[ACCOUNT_BALANCE_INDEX].readUint256();
        codeHash = accountFields[ACCOUNT_CODE_HASH_INDEX].readBytes32();
        storageRoot = accountFields[ACCOUNT_STORAGE_ROOT_INDEX].readBytes32();
    }
}
