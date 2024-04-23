// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {HeadersProcessor} from "./../HeadersProcessor.sol";

interface IL1CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract MessagesInboxOp is Ownable2Step {
    event ReceivedParentHash(uint256 originChainId, bytes32 blockhash, uint256 blockNumber);

    address public crossDomainMsgSender;
    HeadersProcessor public headersProcessor;
    uint256 public messagesOriginChainId;
    IL1CrossDomainMessenger public messenger;

    constructor() Ownable(msg.sender) {
        messenger = IL1CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    }

    function setCrossDomainMsgSender(address _crossDomainMsgSender) external onlyOwner {
        crossDomainMsgSender = _crossDomainMsgSender;
    }

    function setHeadersProcessor(address _headersProcessor) external onlyOwner {
        headersProcessor = HeadersProcessor(_headersProcessor);
    }

    function setMessagesOriginChainId(uint256 _messagesOriginChainId) external onlyOwner {
        messagesOriginChainId = _messagesOriginChainId;
    }

    function setMessengerAddress(address _messengerAddress) external onlyOwner {
        messenger = IL1CrossDomainMessenger(_messengerAddress);
    }

    function receiveParentHashForBlock(uint256 blockNumber, bytes32 parentHash) external onlyCrossdomainCounterpart {
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        emit ReceivedParentHash(messagesOriginChainId, parentHash, blockNumber);
    }

    function receiveKeccakMMR(uint256 aggregatorId, uint256 mmrSize, bytes32 keccakMMRRoot)
        external
        onlyCrossdomainCounterpart
    {
        headersProcessor.createBranchFromMessage(keccakMMRRoot, mmrSize, aggregatorId);
    }

    modifier onlyCrossdomainCounterpart() {
        require(
            msg.sender == address(messenger) && messenger.xDomainMessageSender() == crossDomainMsgSender,
            "Not authorized cross-domain message. Only cross-domain counterpart can call this function."
        );
        _;
    }
}
