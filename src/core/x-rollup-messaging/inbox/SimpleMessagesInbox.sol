// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {AbstractMessagesInbox} from "./AbstractMessagesInbox.sol";

contract SimpleMessagesInbox is AbstractMessagesInbox {
    constructor() {}

    function isCrossdomainCounterpart() public view override returns (bool) {
        return msg.sender == this.crossDomainMsgSender();
    }
}
