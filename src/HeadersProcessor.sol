// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {ICommitmentsInbox} from "./interfaces/ICommitmentsInbox.sol";

contract HeadersProcessor is IHeadersProcessor {
    ICommitmentsInbox public immutable commitmentsInbox;

    constructor(ICommitmentsInbox _commitmentsInbox) {
        commitmentsInbox = _commitmentsInbox;
    }

    mapping(uint256 => bytes32) public receivedParentHashes;

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external onlyCommitmentsInbox {
        receivedParentHashes[blockNumber] = parentHash;
    }

    modifier onlyCommitmentsInbox() {
        require(msg.sender == address(commitmentsInbox), "ERR_ONLY_INBOX");
        _;
    }
}
