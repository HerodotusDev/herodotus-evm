// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersStorage} from "./interfaces/IHeadersStorage.sol";
import {IFactsRegistry} from "./interfaces/IFactsRegistry.sol";

import {RLP} from "./lib/RLP.sol";
import {TrieProofs} from "./lib/TrieProofs.sol";
import {Bitmap16} from "./lib/Bitmap16.sol";

contract FactsRegistry is IFactsRegistry {
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

    IHeadersStorage public immutable headersStorage;

    mapping(address => mapping(uint256 => uint256)) public accountNonces;
    mapping(address => mapping(uint256 => uint256)) public accountBalances;
    mapping(address => mapping(uint256 => bytes32)) public accountCodeHashes;
    mapping(address => mapping(uint256 => bytes32)) public accountStorageHashes;

    constructor(IHeadersStorage _headersStorage) {
        headersStorage = _headersStorage;
    }

    function proveAccount(
        uint16 paramsBitmap,
        uint256 blockNumber,
        address account,
        bytes calldata proof
    ) external {
        bytes32 stateRoot = headersStorage.stateRoots(blockNumber);
        require(stateRoot != bytes32(0), "ERR_EMPTY_STATE_ROOT");

        bytes32 proofPath = keccak256(abi.encodePacked(account));
        bytes memory accountRLP = proof.verify(stateRoot, proofPath);

        bytes32 storageHash = EMPTY_TRIE_ROOT_HASH;
        bytes32 codeHash = EMPTY_CODE_HASH;
        uint256 nonce;
        uint256 balance;

        // TODO check length with assembly to avoid using keccak
        if (keccak256(accountRLP) != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470) {
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

    function proveStorage(
        address account,
        uint256 blockNumber,
        bytes32 slot,
        bytes memory storageProof
    ) public view returns (bytes32) {
        bytes32 root = accountStorageHashes[account][blockNumber];
        require(root != bytes32(0), "ERR_EMPTY_STORAGE_ROOT");
        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        return bytes32(storageProof.verify(root, proofPath).toRLPItem().toUint());
    }
}
