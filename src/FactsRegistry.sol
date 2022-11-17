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

    uint8 private constant ACCOUNT_BALANCE_INDEX = 0;
    uint8 private constant ACCOUNT_NONCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

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

        // STORAGE_HASH
        if (paramsBitmap.readBitAtIndexFromRight(0)) {
            bytes32 storageHash = bytes32(accountRLP.toRLPItem().toList()[ACCOUNT_STORAGE_ROOT_INDEX].toUint());
            accountStorageHashes[account][blockNumber] = storageHash;
        }

        // CODE_HASH
        if (paramsBitmap.readBitAtIndexFromRight(1)) {
            bytes32 codeHash = bytes32(accountRLP.toRLPItem().toList()[ACCOUNT_CODE_HASH_INDEX].toUint());
            accountCodeHashes[account][blockNumber] = codeHash;
        }

        // NONCE
        if (paramsBitmap.readBitAtIndexFromRight(2)) {
            uint256 nonce = accountRLP.toRLPItem().toList()[ACCOUNT_NONCE_INDEX].toUint();
            accountNonces[account][blockNumber] = nonce;
        }

        // BALANCE
        if (paramsBitmap.readBitAtIndexFromRight(3)) {
            uint256 balance = accountRLP.toRLPItem().toList()[ACCOUNT_BALANCE_INDEX].toUint();
            accountBalances[account][blockNumber] = balance;
        }
    }
}
