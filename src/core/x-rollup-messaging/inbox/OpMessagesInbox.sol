// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractMessagesInbox} from "./AbstractMessagesInbox.sol";

interface IL1CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract OpMessagesInbox is AbstractMessagesInbox {
    IL1CrossDomainMessenger public constant MESSENGER = IL1CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    constructor() {}

    function isCrossdomainCounterpart() public view override returns (bool) {
        return msg.sender == address(MESSENGER) && MESSENGER.xDomainMessageSender() == this.crossDomainMsgSender();
    }
}
