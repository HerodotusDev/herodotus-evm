// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {HeadersProcessor} from "../core/HeadersProcessor.sol";
import {EVMHeaderRLP} from "../lib/EVMHeaderRLP.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

contract TimestampToBlockNumberMapper {
    event MapperCreated(uint256 mapperId, uint256 startsFromBlock);

    struct Mapper {
        uint256 startsFromBlock;
        uint256 latestBlockNumberAppended;
        bytes32 root;
    }

    // Calldata encoding facilitator
    struct RemappedBlock {
        uint256 includedInTreeId;
        uint256 leafIndexInUnorderedTree;
        bytes32 leafValueInUnorderedTree;
        bytes32[] inclusionProof;
        bytes32[] peaks;
        bytes header;
    }

    // Calldata encoding facilitator
    struct BinsearchPathElement {
        uint256 leafIndex;
        bytes32 leafValue;
        bytes32[] peaks;
        bytes32[] inclusionProof;
    }

    uint256 private _HASHMAP_KEY_OFFSET = 0xDEFACED00000;

    HeadersProcessor public immutable headersProcessor;

    uint256 public mappersCount;
    mapping(uint256 => Mapper) public mappers; // TODO memento pattern

    constructor(HeadersProcessor _headersProcessor) {
        headersProcessor = _headersProcessor;
    }

    function createMapper(uint256 _startsFromBlock) external returns (uint256 mapperId) {
        mappers[mappersCount] = Mapper(_startsFromBlock, type(uint256).max, bytes32(0));
        emit MapperCreated(mapperId, _startsFromBlock);
        mappersCount++;
    }

    function remapBlocks(uint256 targettedMapId, bytes32[] calldata lastPeaks, RemappedBlock[] calldata blocksToRemap) external {
        Mapper memory mapper = mappers[targettedMapId];
        require(mapper.startsFromBlock != 0, "ERR_MAPPER_DOES_NOT_EXIST"); // TODO this has to be handled

        bytes32[] memory nextPeaks = lastPeaks;
        uint256 nextElementsCount = mapper.latestBlockNumberAppended - mapper.startsFromBlock;
        bytes32 nextRoot = mapper.root;

        uint256 firstBlockAppended = mapper.latestBlockNumberAppended == type(uint).max ? mapper.startsFromBlock : mapper.latestBlockNumberAppended + 1;
        uint256 nextExpectedBlockAppended = firstBlockAppended;

        for(uint256 i = 0 ; i < blocksToRemap.length; i++) {
            require(keccak256(blocksToRemap[i].header) == blocksToRemap[i].leafValueInUnorderedTree, "ERR_INVALID_HEADER");
            
            bytes32 root;
            uint256 elementsCount;

            {
                bytes32 hashmapIndex = keccak256(abi.encodePacked(blocksToRemap[i].includedInTreeId + _HASHMAP_KEY_OFFSET)); // TODO use more efficient hash function
                assembly ("memory-safe") { // TODO idk what memory-safe actually does
                    root := mload(add(hashmapIndex, 32))
                    elementsCount := mload(add(hashmapIndex, 64))
                }

                // In this case SLOAD from HeaderProcessor is needed
                if(root == bytes32(0)) {
                    (uint256 mmrSize, bytes32 mmrRoot, ) = headersProcessor.mmrs(blocksToRemap[i].includedInTreeId);
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
                blocksToRemap[i].leafIndexInUnorderedTree,
                blocksToRemap[i].leafValueInUnorderedTree,
                blocksToRemap[i].inclusionProof,
                blocksToRemap[i].peaks,
                elementsCount,
                root
            );

            uint256 blockNumber = EVMHeaderRLP.getBlockNumber(blocksToRemap[i].header);
            require(blockNumber == nextExpectedBlockAppended, "ERR_BLOCK_NUMBER_TOO_LOW");
            uint256 timestamp = EVMHeaderRLP.getTimestamp(blocksToRemap[i].header);
            (nextElementsCount, nextRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(bytes32(timestamp), nextPeaks, nextElementsCount, nextRoot);
            nextExpectedBlockAppended++;
        }

        mappers[targettedMapId].latestBlockNumberAppended = nextElementsCount + firstBlockAppended;
        mappers[targettedMapId].root = nextRoot;
    }

    function binsearchBlockNumberByTimestamp(uint256 searchedRemappingId, uint256 timestamp, BinsearchPathElement[] calldata searchPath) external view returns(uint256 blockNumber) {
        uint256 remappedTreeSize = mappers[searchedRemappingId].latestBlockNumberAppended - mappers[searchedRemappingId].startsFromBlock;
        bytes32 remappedRoot = mappers[searchedRemappingId].root;
        require(remappedRoot != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        uint256 currentElement = remappedTreeSize / 2;

        for(uint256 i = 0; i < searchPath.length; i++) {
            require(searchPath[i].leafIndex == currentElement, "ERR_INVALID_SEARCH_PATH");

            StatelessMmr.verifyProof(
                searchPath[i].leafIndex,
                searchPath[i].leafValue,
                searchPath[i].inclusionProof,
                searchPath[i].peaks,
                remappedTreeSize,
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