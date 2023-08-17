// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


import {IMessagesInbox} from "./interfaces/IMessagesInbox.sol";
import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";


contract MessagesInbox is IMessagesInbox {
    event ReceivedParentHash(uint8 originChainId, bytes32 blockhash, uint256 blockNumber);

    address public immutable crossDomainMsgSender;
    IHeadersProcessor public immutable headersProcessor;

    constructor(address _crossDomainMsgSender, IHeadersProcessor _headersProcessor) {
        crossDomainMsgSender = _crossDomainMsgSender;
        headersProcessor = _headersProcessor;
    }

    function receiveParentHashForBlock(bytes32 parentHash, uint256 blockNumber) external onlyCrossdomainCounterpart {
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        emit ReceivedParentHash(uint8(1), parentHash, blockNumber); // TODO: Handle originChainId
    }

    modifier onlyCrossdomainCounterpart() {
        require(msg.sender == crossDomainMsgSender);
        _;
    }
}
