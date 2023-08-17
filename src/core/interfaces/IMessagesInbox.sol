// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMessagesInbox {
    event FraudProven(uint256 fraudaulentBlock, bytes32 validParentHash, bytes32 invalidParentHash, address penaltyRecipient);
}
