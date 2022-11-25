// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IReceiptProofRecipient {
    struct ReceiptContext {
        bytes32 txHash;
        uint256 gasUsed;
        bytes logs;
    }

    function consumeAccountProof(ReceiptContext calldata receiptCtx, bytes calldata additionalCtx) external;
}
