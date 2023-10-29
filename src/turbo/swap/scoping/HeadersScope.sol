// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {HeadersProcessor} from "../../../core/HeadersProcessor.sol";
import {EVMHeaderRLP} from "../../../lib/EVMHeaderRLP.sol";
import {HeaderProperty} from "../../interfaces/IQuerableTurboSwap.sol";

import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";


// TODO: implement
abstract contract TurboSwapHeaders {
    using EVMHeaderRLP for bytes;
    
    struct HeaderPropertiesAttestation {
        uint256 chainId;
        HeaderProperty[] properties;
        // Proof section
        uint256 treeId;
        uint256 blockProofLeafIndex;
        bytes32 blockProofLeafValue;
        uint256 mmrTreeSize;
        bytes32[] inclusionProof;
        bytes32[] mmrPeaks;
        bytes headerSerialized;
    }

    struct HeaderReset {
        uint256 chainId;
        uint256 blockNumber;
        HeaderProperty[] properties;
    }

    function _swapFullfilmentAssignee() internal virtual view returns(address);

    function _getHeadersProcessorForChain(uint256 chainId) internal virtual view returns(HeadersProcessor);

    // chainid => block number => HeaderProperty => value
    mapping(uint256 => mapping(uint256 => mapping(HeaderProperty => bytes32))) internal _headers;

    function setMultipleHeaderProps(HeaderPropertiesAttestation[] calldata attestations) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < attestations.length; i++) {
            HeaderPropertiesAttestation calldata attestation = attestations[i];

            HeadersProcessor headersProcessor = _getHeadersProcessorForChain(attestation.chainId);
            require(address(headersProcessor) != address(0), "TurboSwap: Unknown chain id");

            bytes32 mmrRoot = headersProcessor.getLatestMMRRoot(attestation.treeId); // TODO this should include size
            require(mmrRoot != bytes32(0), "ERR_EMPTY_MMR_ROOT");

            require(keccak256(attestation.headerSerialized) == attestation.blockProofLeafValue, "ERR_INVALID_PROOF_LEAF");
            StatelessMmr.verifyProof(attestation.blockProofLeafIndex, attestation.blockProofLeafValue, attestation.inclusionProof, attestation.mmrPeaks, attestation.mmrTreeSize, mmrRoot);

            uint256 blockNumber = attestation.headerSerialized.getBlockNumber();

            for(uint256 j = 0; j < attestation.properties.length; j++) {
                HeaderProperty property = attestation.properties[j];
                // bytes32 value = headerSerialized.getHeaderProperty(property); // TODO: implement
                _headers[attestation.chainId][blockNumber][property] = bytes32(0); // TODO: implement
            }
        }
    }

    function clearMultipleStorageSlots(HeaderReset[] calldata resets) external {
        require(msg.sender == _swapFullfilmentAssignee(), "TurboSwap: Only current auction winner can call this function");
        for(uint256 i = 0; i < resets.length; i++) {
            HeaderReset calldata reset = resets[i];
            for(uint256 j = 0; j < reset.properties.length; j++) {
                HeaderProperty property = reset.properties[j];
                _headers[reset.chainId][reset.blockNumber][property] = bytes32(0);
            }
            // TODO pay out fees
        }
    }
}