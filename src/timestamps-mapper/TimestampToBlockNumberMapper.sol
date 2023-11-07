// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {HeadersProcessor} from "../core/HeadersProcessor.sol";
import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";
import {Types} from "../lib/Types.sol";

import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {StatelessMmrHelpers} from "solidity-mmr/lib/StatelessMmrHelpers.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";


contract TimestampToBlockNumberMapper {
    event MapperCreated(uint256 mapperId, uint256 startsFromBlock);
    event RemappedBlocksBatch(uint256 mapperId, uint256 startsFromBlock, uint256 endsAtBlock, bytes32 mmrRoot, uint256 mmrSize);

    /// @notice struct stored in the contract storage, represents the mapper
    struct MapperInfo {
        /// @notice initialized represents whether the mapper has been initialized or not, because 0 is a valid block number
        bool initialized;

        /// @notice startsFromBlock represents the block number from which the remapping MMR starts
        uint256 startsFromBlock;

        /// @notice latestSize represents the latest size of the MMR
        uint256 latestSize;

        /// @notice mmrSizeToRoot maps the MMR size to the MMR root, that way we have automatic versioning
        mapping(uint256 => bytes32) mmrSizeToRoot;
    }

    /// @notice struct passed as calldata, represents the binsearch path element
    struct BinsearchPathElement {
        uint256 elementIndex;
        bytes32 leafValue;
        bytes32[] inclusionProof;
    }

    /// @notice offset used to calculate memory keys in order to avoid collisions when memoizing
    uint256 private _HASHMAP_KEY_OFFSET = 0xDEFACED00000;

    /// @notice headersProcessor is the address of the headers processor contract
    HeadersProcessor public immutable headersProcessor;

    /// @notice mappersCount represents the number of mappers created
    uint256 public mappersCount;

    /// @notice mappers maps the mapper id to the mapper info
    mapping(uint256 => MapperInfo) public mappers;

    /// @notice constructor
    /// @param _headersProcessor the address of the headers processor contract
    constructor(address _headersProcessor) {
        headersProcessor = HeadersProcessor(_headersProcessor);
    }

    /// @notice creates a new mapper
    /// @param _startsFromBlock the block number from which the remapping MMR starts
    /// @return mapperId the id of the created mapper
    function createMapper(uint256 _startsFromBlock) external returns (uint256 mapperId) {
        mapperId = mappersCount;
        mappers[mapperId].initialized = true;
        mappers[mapperId].startsFromBlock = _startsFromBlock;
        emit MapperCreated(mapperId, _startsFromBlock);
        mappersCount++;
    }

    /// @notice appends a batch of headers to the remapping MMR
    /// @notice Reindexing MMRs are always grown from their latest size, thus they're frontrunnable
    /// @param targettedMapId the id of the mapper to which the headers are appended
    /// @param lastPeaks the peaks of the grown remapping MMR
    /// @param headersWithProofs the headers with their proofs against the MMR managed by the headers processor
    function reindexBatch(uint256 targettedMapId, bytes32[] calldata lastPeaks, Types.BlockHeaderProof[] calldata headersWithProofs) external {
        // Ensure that remapper exists at the given id
        bool isInitialized = mappers[targettedMapId].initialized;
        require(isInitialized, "ERR_UNINITIALIZED_MAPPER");

        // Load remapper start block from storage
        uint256 mapperStartBlock = mappers[targettedMapId].startsFromBlock;

        // Load latest remapper size and root from storage
        uint256 mapperLatestSize = mappers[targettedMapId].latestSize;
        bytes32 mapperLatestRoot = mappers[targettedMapId].mmrSizeToRoot[mapperLatestSize];

        // Calculate the remapper number of leaves(number of blocks remapped) from the latest size
        uint256 mapperLeavesCount = StatelessMmrHelpers.mmrSizeToLeafCount(mapperLatestSize);

        // Create a mutable in memory copy of the MMR state
        bytes32[] memory nextPeaks = lastPeaks;
        uint256 nextSize = mapperLatestSize;
        bytes32 nextRoot = mapperLatestRoot;

        // Create mutable in memory copy of the first block number that will be appended to the remapping MMR
        uint256 nextExpectedBlockAppended = mapperStartBlock + mapperLeavesCount;

        // Iterate over the headers with proofs
        for(uint256 i = 0 ; i < headersWithProofs.length; i++) {    
            uint256 elementsCount = headersWithProofs[i].mmrTreeSize;   
            bytes32 root = headersProcessor.getMMRRoot(headersWithProofs[i].treeId, elementsCount);
            require(root != bytes32(0), "ERR_INVALID_TREE_ID");

            // Verify the proof against the MMR root
            StatelessMmr.verifyProof(
                headersWithProofs[i].blockProofLeafIndex,
                keccak256(headersWithProofs[i].provenBlockHeader),
                headersWithProofs[i].mmrElementInclusionProof,
                headersWithProofs[i].mmrPeaks,
                elementsCount,
                root
            );
            
            // Verify that the block number of the proven header is the next expected one
            uint256 blockNumber = EVMHeaderRLP.getBlockNumber(headersWithProofs[i].provenBlockHeader);
            require(blockNumber == nextExpectedBlockAppended, "ERR_UNEXPECTED_BLOCK_NUMBER");

            // Decode the timestamp from the proven header
            uint256 timestamp = EVMHeaderRLP.getTimestamp(headersWithProofs[i].provenBlockHeader);

            // Append the timestamp to the remapping MMR
            (nextSize, nextRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(bytes32(timestamp), nextPeaks, nextSize, nextRoot);

            // Increment the next expected block number
            nextExpectedBlockAppended++;
        }

        // Update the remapper state
        mappers[targettedMapId].latestSize = nextSize;
        mappers[targettedMapId].mmrSizeToRoot[nextSize] = nextRoot;

        emit RemappedBlocksBatch(targettedMapId, mapperStartBlock, nextExpectedBlockAppended - 1, nextRoot, nextSize);
    }

    function binsearchBlockNumberByTimestamp(uint256 searchedRemappingId, uint256 searchAtSize, bytes32[] calldata peaks, uint256 timestamp, BinsearchPathElement[] calldata searchPath) external view returns(uint256 blockNumber) {
        // Ensure that remapper exists at the given id and size
        bytes32 rootAtGivenSize = mappers[searchedRemappingId].mmrSizeToRoot[searchAtSize];
        require(rootAtGivenSize != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        uint256 remappedBlocksAmount = StatelessMmrHelpers.mmrSizeToLeafCount(searchAtSize);
        bytes32 remappedRoot = rootAtGivenSize;

        uint256 lowerBound = 0;
        uint256 upperBound = remappedBlocksAmount;

        for(uint256 i = 0; i < searchPath.length; i++) {
            uint256 leafIndex = StatelessMmrHelpers.mmrIndexToLeafIndex(searchPath[i].elementIndex);
            uint256 currentElement = (lowerBound + upperBound) / 2;
            require(leafIndex == currentElement, "ERR_INVALID_SEARCH_PATH");
            
            StatelessMmr.verifyProof(
                searchPath[i].elementIndex,
                searchPath[i].leafValue,
                searchPath[i].inclusionProof,
                peaks,
                searchAtSize,
                remappedRoot
            );

            if(timestamp < uint256(searchPath[i].leafValue)) {
                require(currentElement >= 1, "ERR_SEARCH_BOUND_OUT_OF_RANGE");
                upperBound = currentElement - 1;
            } else {
                lowerBound = currentElement;
            }
        }

        uint256 foundBlockNumber = mappers[searchedRemappingId].startsFromBlock + lowerBound;
        return foundBlockNumber;
    }

    function isMapperInitialized(uint256 mapperId) external view returns(bool) {
        return mappers[mapperId].initialized;
    }

    function getMapperStartsFromBlock(uint256 mapperId) external view returns(uint256) {
        return mappers[mapperId].startsFromBlock;
    }

    function getMapperLatestSize(uint256 mapperId) external view returns(uint256) {
        return mappers[mapperId].latestSize;
    }

    function getMapperLatestRoot(uint256 mapperId) external view returns(bytes32) {
        return mappers[mapperId].mmrSizeToRoot[mappers[mapperId].latestSize];
    }

    function getMapperRootAtSize(uint256 mapperId, uint256 size) external view returns(bytes32) {
        return mappers[mapperId].mmrSizeToRoot[size];
    }
}