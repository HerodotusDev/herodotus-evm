// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;


import {HeadersProcessor} from "./HeadersProcessor.sol";


contract MessagesInbox {
    event ReceivedParentHash(uint8 originChainId, bytes32 blockhash, uint256 blockNumber);

    address public immutable crossDomainMsgSender;
    HeadersProcessor public immutable headersProcessor;

    constructor(address _crossDomainMsgSender, address _headersProcessor) {
        crossDomainMsgSender = _crossDomainMsgSender;
        headersProcessor = HeadersProcessor(_headersProcessor);
    }

    function receiveParentHashForBlock(bytes32 parentHash, uint256 blockNumber) external onlyCrossdomainCounterpart {
        headersProcessor.receiveParentHash(blockNumber, parentHash);
        emit ReceivedParentHash(uint8(1), parentHash, blockNumber); // TODO: Handle originChainId
    }

    function receiveKeccakMMR(uint256 aggregatorId, uint256 mmrSize, bytes32 keccakMMRRoot) external onlyCrossdomainCounterpart {
        headersProcessor.createBranchFromMessage(keccakMMRRoot, mmrSize, aggregatorId);
    }

    modifier onlyCrossdomainCounterpart() {
        require(msg.sender == crossDomainMsgSender);
        _;
    }
}
