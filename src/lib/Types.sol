// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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

    struct AccountTrieProof {
        bytes[] trieProof;
        bytes accountRLP; // This might be not needed as the last element of the trieProof contains the accountRLP
    }
}