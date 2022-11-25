// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ITransactionProofRecipient {
    struct TransactionContext {
        bytes32 txHash;
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 value;
    }

    function consumeAccountProof(TransactionContext calldata transactionCtx, bytes calldata additionalCtx) external;
}
