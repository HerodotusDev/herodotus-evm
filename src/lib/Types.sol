// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

library Types {
    struct BlockHeaderProof {
        uint256 treeId;
        uint256 mmrTreeSize;
        uint256 blockNumber;
        uint256 blockProofLeafIndex;
        bytes32[] mmrPeaks;
        bytes32[] mmrElementInclusionProof;
        bytes provenBlockHeader;
    }

    enum AccountFields {
        NONCE,
        BALANCE,
        STORAGE_ROOT,
        CODE_HASH
    }
}
