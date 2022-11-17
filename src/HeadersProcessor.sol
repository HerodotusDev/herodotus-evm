// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {ICommitmentsInbox} from "./interfaces/ICommitmentsInbox.sol";

import {EVMHeaderRLP} from "./lib/EVMHeaderRLP.sol";
import {Bitmap16} from "./lib/Bitmap16.sol";

contract HeadersProcessor is IHeadersProcessor {
    using Bitmap16 for uint16;
    using EVMHeaderRLP for bytes;

    ICommitmentsInbox public immutable commitmentsInbox;

    uint256 public latestReceived;
    mapping(uint256 => bytes32) public receivedParentHashes;

    mapping(uint256 => bytes32) public parentHashes;
    mapping(uint256 => bytes32) public stateRoots;
    mapping(uint256 => bytes32) public receiptsRoots;
    mapping(uint256 => bytes32) public transactionsRoots;
    mapping(uint256 => bytes32) public unclesHashes;

    constructor(ICommitmentsInbox _commitmentsInbox) {
        commitmentsInbox = _commitmentsInbox;
    }

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external onlyCommitmentsInbox {
        if (blockNumber > latestReceived) {
            latestReceived = blockNumber;
        }
        receivedParentHashes[blockNumber] = parentHash;
    }

    function processBlockFromVerifiedHash(
        uint16 paramsBitmap,
        uint256 blockNumber,
        bytes calldata headerSerialized
    ) external {
        bytes32 expectedHash = receivedParentHashes[blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bool isValid = isHeaderValid(expectedHash, headerSerialized);
        require(isValid, "ERR_INVALID_HEADER");

        _processBlock(paramsBitmap, blockNumber, headerSerialized);
    }

    function processBlock(
        uint16 paramsBitmap,
        uint256 blockNumber,
        bytes calldata headerSerialized
    ) external {
        bytes32 expectedHash = parentHashes[blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bool isValid = isHeaderValid(expectedHash, headerSerialized);
        require(isValid, "ERR_INVALID_HEADER");

        _processBlock(paramsBitmap, blockNumber, headerSerialized);
    }

    function _processBlock(
        uint16 paramsBitmap,
        uint256 blockNumber,
        bytes calldata headerSerialized
    ) internal {
        bytes32 parentHash = headerSerialized.getParentHash();
        parentHashes[blockNumber] = parentHash;

        // Uncles hash
        if (paramsBitmap.readBitAtIndexFromRight(1)) {
            bytes32 unclesHash = headerSerialized.getUnclesHash();
            unclesHashes[blockNumber] = unclesHash;
        }

        // State root
        if (paramsBitmap.readBitAtIndexFromRight(3)) {
            bytes32 stateRoot = headerSerialized.getStateRoot();
            stateRoots[blockNumber] = stateRoot;
        }

        // Transactions root
        if (paramsBitmap.readBitAtIndexFromRight(4)) {
            bytes32 transactionsRoot = headerSerialized.getTransactionsRoot();
            transactionsRoots[blockNumber] = transactionsRoot;
        }

        // Receipts root
        if (paramsBitmap.readBitAtIndexFromRight(5)) {
            bytes32 receiptsRoot = headerSerialized.getReceiptsRoot();
            receiptsRoots[blockNumber] = receiptsRoot;
        }
    }

    function isHeaderValid(bytes32 hash, bytes memory header) public pure returns (bool) {
        return keccak256(header) == hash;
    }

    modifier onlyCommitmentsInbox() {
        require(msg.sender == address(commitmentsInbox), "ERR_ONLY_INBOX");
        _;
    }
}
