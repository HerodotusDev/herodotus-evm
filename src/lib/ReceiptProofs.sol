// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {EVMHeaderRLP} from "./EVMHeaderRLP.sol";
import {TrieProofs} from "./TrieProofs.sol";

library ReceiptProofs {
    using EVMHeaderRLP for bytes;
    using TrieProofs for bytes;

    function verify(bytes memory headerSerialized, uint256 transactionIndex, bytes memory receiptProof) internal pure {
        uint256 blockNumber = headerSerialized.getBlockNumber();
        bytes32 receiptsRoot = headerSerialized.getReceiptsRoot();

        bytes32 proofPath = keccak256(abi.encodePacked(blockNumber, transactionIndex));
        bytes memory receiptRLP = receiptProof.verify(receiptsRoot, proofPath);
    }
}
