// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library FixedSizeMerkleTree {
    
    function updateElement(bytes32 root, uint256 treeDepth, uint256 leafIndex, bytes32 oldLeafValue, bytes32 newLeafValue, bytes32[] memory inclusionProof) internal pure returns(bytes32) {
        // Use the `verifyInclusionProof` function to ensure the old value's inclusion proof is valid
        bool isProofValid = verifyInclusionProof(root, leafIndex, oldLeafValue, inclusionProof);
        require(isProofValid, "Invalid proof");
        
        uint256 currentIndex = leafIndex;
        uint256 currentDepth = treeDepth;
        bytes32 currentValue = newLeafValue;
        
        for (uint256 i = 0; i < inclusionProof.length; i++) {
            bool isCurrentIndexEven = currentIndex % 2 == 0;
            currentValue = isCurrentIndexEven ? keccak256(abi.encodePacked(currentValue, inclusionProof[i])) : keccak256(abi.encodePacked(inclusionProof[i], currentValue));
            
            currentDepth--;
            currentIndex = currentIndex / 2;
            if (currentDepth == 0) break;
        }
        
        return currentValue;
    }

    function verifyInclusionProof(bytes32 root, uint256 leafIndex, bytes32 leafValue, bytes32[] memory inclusionProof) internal pure returns (bool) {
        uint256 currentIndex = leafIndex;
        bytes32 currentValue = leafValue;
        
        for (uint256 i = 0; i < inclusionProof.length; i++) {
            bool isCurrentIndexEven = currentIndex % 2 == 0;
            currentValue = isCurrentIndexEven ? keccak256(abi.encodePacked(currentValue, inclusionProof[i])) : keccak256(abi.encodePacked(inclusionProof[i], currentValue));
            currentIndex = currentIndex / 2;
        }
        return root == currentValue;
    }
}