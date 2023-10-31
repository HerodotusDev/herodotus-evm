// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;


import {HeadersProcessor} from "./HeadersProcessor.sol";


contract MessagesInbox {
    event ReceivedParentHash(uint256 originChainId, bytes32 blockhash, uint256 blockNumber);

    address public immutable crossDomainMsgSender;
    HeadersProcessor public immutable headersProcessor;
    uint256 public immutable messagesOriginChainId;

    constructor(address _crossDomainMsgSender, address _headersProcessor, uint256 _messagesOriginChainId) {
        crossDomainMsgSender = _crossDomainMsgSender;
        headersProcessor = HeadersProcessor(_headersProcessor);
        messagesOriginChainId = _messagesOriginChainId;
    }

    function receiveParentHashForBlock(uint256 blockNumber, bytes32 parentHash) external onlyCrossdomainCounterpart {
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        emit ReceivedParentHash(messagesOriginChainId, parentHash, blockNumber);
    }

    function receiveKeccakMMR(uint256 aggregatorId, uint256 mmrSize, bytes32 keccakMMRRoot) external onlyCrossdomainCounterpart {
        headersProcessor.createBranchFromMessage(keccakMMRRoot, mmrSize, aggregatorId);
    }

    modifier onlyCrossdomainCounterpart() {
        require(msg.sender == crossDomainMsgSender);
        _;
    }
}
