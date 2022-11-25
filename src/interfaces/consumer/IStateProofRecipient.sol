// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStateProofRecipient {
    struct AccountContext {
        uint256 blockNumber;
        address account;
        uint256 balance;
        uint256 nonce;
        bytes32 storageHash;
        bytes32 codeHash;
    }

    function consumeAccountProof(AccountContext calldata accountCtx, bytes calldata additionalCtx) external;
}
