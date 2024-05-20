// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {HeadersStore} from "../../HeadersStore.sol";

abstract contract AbstractMessagesInbox is Ownable2Step {
    event ReceivedHash(uint256 originChainId, bytes32 blockhash, uint256 blockNumber);

    address public crossDomainMsgSender;
    HeadersStore public headersStore;
    uint256 public messagesOriginChainId;

    constructor() Ownable(msg.sender) {}

    function setCrossDomainMsgSender(address _crossDomainMsgSender) external onlyOwner {
        crossDomainMsgSender = _crossDomainMsgSender;
    }

    function setHeadersStore(address _headersStore) external onlyOwner {
        headersStore = HeadersStore(_headersStore);
    }

    function setMessagesOriginChainId(uint256 _messagesOriginChainId) external onlyOwner {
        messagesOriginChainId = _messagesOriginChainId;
    }

    function receiveHashForBlock(uint256 blockNumber, bytes32 parentHash) external onlyCrossdomainCounterpart {
        headersStore.receiveHash(blockNumber, parentHash);
        emit ReceivedHash(messagesOriginChainId, parentHash, blockNumber);
    }

    function receiveKeccakMMR(uint256 assignedId, uint256 aggregatorId, uint256 mmrSize, bytes32 keccakMMRRoot) external onlyCrossdomainCounterpart {
        headersStore.createBranchFromMessage(assignedId, keccakMMRRoot, mmrSize, aggregatorId);
    }

    function isCrossdomainCounterpart() public view virtual returns (bool);

    modifier onlyCrossdomainCounterpart() {
        require(isCrossdomainCounterpart(), "Not authorized cross-domain message. Only cross-domain counterpart can call this function.");
        _;
    }
}
