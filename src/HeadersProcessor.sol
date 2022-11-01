// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {ICommitmentsInbox} from "./interfaces/ICommitmentsInbox.sol";

contract HeadersProcessor is IHeadersProcessor {
    ICommitmentsInbox public immutable commitmentsInbox;

    uint256 public latestReceived;
    mapping(uint256 => bytes32) public receivedParentHashes;

    mapping(uint256 => bytes32) public parentHashes;
    mapping(uint256 => bytes32) public stateRoots;
    mapping(uint256 => bytes32) public receiptsRoots;
    mapping(uint256 => bytes32) public transactionsRoots;
    mapping(uint256 => bytes32) public unclesHash;

    constructor(ICommitmentsInbox _commitmentsInbox) {
        commitmentsInbox = _commitmentsInbox;
    }

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external onlyCommitmentsInbox {
        if (blockNumber > latestReceived) {
            latestReceived = blockNumber;
        }
        receivedParentHashes[blockNumber] = parentHash;
    }

    function processBlock(uint256 blockNumber, bytes calldata headerSerialized) external {
        bytes32 expectedHash = receivedParentHashes[blockNumber + 1];
        require(expectedHash != bytes32(0));

        bytes32 actualHash = keccak256(headerSerialized);
        require(actualHash == expectedHash);

        
    }

    modifier onlyCommitmentsInbox() {
        require(msg.sender == address(commitmentsInbox), "ERR_ONLY_INBOX");
        _;
    }
}
