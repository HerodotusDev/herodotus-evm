// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {HeadersProcessor} from "../../HeadersProcessor.sol";

abstract contract AbstractMessagesInbox is Ownable2Step {
    event ReceivedParentHash(uint256 originChainId, bytes32 blockhash, uint256 blockNumber);
    event ReveivedKeccakMMR(uint256 aggregatorId, uint256 mmrSize, bytes32 keccakMMRRoot, bytes32 newMMRId);

    address public crossDomainMsgSender;
    HeadersProcessor public headersProcessor;
    uint256 public messagesOriginChainId;

    constructor() Ownable(msg.sender) {}

    function setCrossDomainMsgSender(address _crossDomainMsgSender) external onlyOwner {
        crossDomainMsgSender = _crossDomainMsgSender;
    }

    function setHeadersProcessor(address _headersProcessor) external onlyOwner {
        headersProcessor = HeadersProcessor(_headersProcessor);
    }

    function setMessagesOriginChainId(uint256 _messagesOriginChainId) external onlyOwner {
        messagesOriginChainId = _messagesOriginChainId;
    }

    function receiveParentHashForBlock(uint256 blockNumber, bytes32 parentHash) external onlyCrossdomainCounterpart {
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        emit ReceivedParentHash(messagesOriginChainId, parentHash, blockNumber);
    }

    function receiveKeccakMMR(uint256 aggregatorId, uint256 mmrSize, bytes32 keccakMMRRoot, bytes32 newMMRId) external onlyCrossdomainCounterpart {
        headersProcessor.createBranchFromMessage(keccakMMRRoot, mmrSize, aggregatorId, newMMRId);
        emit ReveivedKeccakMMR(aggregatorId, mmrSize, keccakMMRRoot, newMMRId);
    }

    function isCrossdomainCounterpart() public view virtual returns (bool);

    modifier onlyCrossdomainCounterpart() {
        require(isCrossdomainCounterpart(), "Not authorized cross-domain message. Only cross-domain counterpart can call this function.");
        _;
    }
}
