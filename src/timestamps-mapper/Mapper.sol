// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {HeadersProcessor} from "../core/HeadersProcessor.sol";
import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";
import {Types} from "../lib/Types.sol";

import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {StatelessMmrHelpers} from "solidity-mmr/lib/StatelessMmrHelpers.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";


contract TimestampToBlockNumberMapper {
    event MapperCreated(uint256 mapperId, uint256 startsFromBlock);

    /// @notice struct stored in the contract storage, represents the mapper
    struct MapperInfo {
        /// @notice startsFromBlock represents the block number from which the remapping MMR starts
        uint256 startsFromBlock;

        /// @notice latestSize represents the latest size of the MMR
        uint256 latestSize;

        /// @notice mmrSizeToRoot maps the MMR size to the MMR root, that way we have automatic versioning
        mapping(uint256 => bytes32) mmrSizeToRoot;
    }

    /// @notice struct passed as calldata, represents the binsearch path element
    struct BinsearchPathElement {
        uint256 leafIndex;
        bytes32 leafValue;
        bytes32[] peaks;
        bytes32[] inclusionProof;
    }

    uint256 private _HASHMAP_KEY_OFFSET = 0xDEFACED00000;

    HeadersProcessor public immutable headersProcessor;

    uint256 public mappersCount;
    mapping(uint256 => MapperInfo) public mappers; // TODO memento pattern

    constructor(HeadersProcessor _headersProcessor) {
        headersProcessor = _headersProcessor;
    }

    /// @notice creates a new mapper
    /// @param _startsFromBlock the block number from which the remapping MMR starts
    /// @return mapperId the id of the created mapper
    function createMapper(uint256 _startsFromBlock) external returns (uint256 mapperId) {
        mapperId = mappersCount;
        mappers[mapperId].startsFromBlock = _startsFromBlock;
        emit MapperCreated(mapperId, _startsFromBlock);
        mappersCount++;
    }

    /// @notice appends a batch of headers to the remapping MMR
    /// @param targettedMapId the id of the mapper to which the headers are appended
    /// @param lastPeaks the peaks of the grown remapping MMR
    /// @param headersWithProofs the headers with their proofs against the MMR managed by the headers processor
    function reindexBatch(uint256 targettedMapId, bytes32[] calldata lastPeaks, Types.BlockHeaderProof[] calldata headersWithProofs) external {
        uint256 mapperStartBlock = mappers[targettedMapId].startsFromBlock;
        require(mapperStartBlock != 0, "ERR_MAPPER_DOES_NOT_EXIST"); // TODO handle 0 start block

        uint256 mapperLatestSize = mappers[targettedMapId].latestSize;
        bytes32 mapperLatestRoot = mappers[targettedMapId].mmrSizeToRoot[mapperLatestSize];

        uint256 mapperLeavesCount = StatelessMmrHelpers.mmrSizeToLeafCount(mapperLatestSize);

        bytes32[] memory nextPeaks = lastPeaks;
        uint256 nextSize = mapperLatestSize;
        bytes32 nextRoot = mapperLatestRoot;

        uint256 firstBlockAppended = Math.max(mapperStartBlock, mapperStartBlock + mapperLeavesCount);
        uint256 nextExpectedBlockAppended = firstBlockAppended;

        for(uint256 i = 0 ; i < headersWithProofs.length; i++) {            
            bytes32 root;
            uint256 elementsCount;

            {
                bytes32 hashmapIndex = keccak256(abi.encodePacked(headersWithProofs[i].treeId + _HASHMAP_KEY_OFFSET)); // TODO use more efficient hash function
                assembly ("memory-safe") { // TODO idk what memory-safe actually does
                    root := mload(add(hashmapIndex, 32))
                    elementsCount := mload(add(hashmapIndex, 64))
                }

                // In this case SLOAD from HeaderProcessor is needed
                if(root == bytes32(0)) {
                    uint256 mmrSize = headersProcessor.getLatestMMRSize(headersWithProofs[i].treeId); // TODO wrong
                    bytes32 mmrRoot = headersProcessor.getLatestMMRRoot(headersWithProofs[i].treeId); // TODO wrong
                    assembly ("memory-safe") { // TODO idk what memory-safe actually does
                        root := mmrRoot
                        elementsCount := mmrSize
                        mstore(add(hashmapIndex, 32), mmrRoot)
                        mstore(add(hashmapIndex, 64), mmrSize)
                    }
                }
                require(root != bytes32(0), "ERR_INVALID_TREE_ID");
            }

            StatelessMmr.verifyProof(
                headersWithProofs[i].blockProofLeafIndex,
                keccak256(headersWithProofs[i].provenBlockHeader),
                headersWithProofs[i].mmrElementInclusionProof,
                headersWithProofs[i].mmrPeaks,
                elementsCount,
                root
            );

            uint256 blockNumber = EVMHeaderRLP.getBlockNumber(headersWithProofs[i].provenBlockHeader);
            require(blockNumber == nextExpectedBlockAppended, "ERR_BLOCK_NUMBER_TOO_LOW");
            uint256 timestamp = EVMHeaderRLP.getTimestamp(headersWithProofs[i].provenBlockHeader);
            (nextSize, nextRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(bytes32(timestamp), nextPeaks, nextSize, nextRoot);
            nextExpectedBlockAppended++;
        }

        mappers[targettedMapId].latestSize = nextSize;
        mappers[targettedMapId].mmrSizeToRoot[nextSize] = nextRoot;
    }

    function binsearchBlockNumberByTimestamp(uint256 searchedRemappingId, uint256 searchAtSize, uint256 timestamp, BinsearchPathElement[] calldata searchPath) external view returns(uint256 blockNumber) {
        // Ensure that remapper exists at the given id and size
        bytes32 rootAtGivenSize = mappers[searchedRemappingId].mmrSizeToRoot[searchAtSize];
        require(rootAtGivenSize != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        uint256 remappedBlocksAmount = StatelessMmrHelpers.mmrSizeToLeafCount(searchAtSize);
        bytes32 remappedRoot = rootAtGivenSize;

        require(remappedRoot != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        uint256 currentElement = remappedBlocksAmount / 2;

        for(uint256 i = 0; i < searchPath.length; i++) {
            require(searchPath[i].leafIndex == currentElement, "ERR_INVALID_SEARCH_PATH");

            StatelessMmr.verifyProof(
                searchPath[i].leafIndex,
                searchPath[i].leafValue,
                searchPath[i].inclusionProof,
                searchPath[i].peaks,
                remappedBlocksAmount,
                remappedRoot
            );

            if(timestamp < uint256(searchPath[i].leafValue)) {
                currentElement = currentElement / 2;
            } else {
                currentElement = currentElement + (currentElement / 2);
            }
        }

        uint256 foundBlockNumber = mappers[searchedRemappingId].startsFromBlock + searchPath[searchPath.length - 1].leafIndex;

        // TODO implement the right-most element retrieval
        return foundBlockNumber;
    }
}