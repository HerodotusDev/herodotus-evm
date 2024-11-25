// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IApeChainInbox} from "./interfaces/IApeChainInbox.sol";

contract ApeChainMessageForwarder is Ownable2Step {
    address public crossDomainMsgSender;
    IApeChainInbox public immutable apeChainInbox;
    IERC20 public immutable apeCoin;

    constructor(IApeChainInbox _apeChainInbox, IERC20 _apeCoin) Ownable(msg.sender) {
        apeChainInbox = _apeChainInbox;
        apeCoin = _apeCoin;
    }

    function forwardMessageToApeChain(
        address l3Target,
        uint l3MaxSubmissionCost,
        uint l3GasLimit,
        uint l3MaxFeePerGas,
        uint tokenTotalFeeAmount,
        bytes calldata messageData
    ) external payable {
        require(msg.sender == crossDomainMsgSender, "Not authorized cross-domain message. Only cross-domain counterpart can call this function.");

        apeCoin.approve(address(apeChainInbox), tokenTotalFeeAmount);

        apeChainInbox.createRetryableTicket(l3Target, 0, l3MaxSubmissionCost, address(this), address(0), l3GasLimit, l3MaxFeePerGas, tokenTotalFeeAmount, messageData);
    }

    function transferFunds(address recipient, uint amount) external onlyOwner {
        apeCoin.transfer(recipient, amount);
    }

    function setCrossDomainMsgSender(address _crossDomainMsgSender) external onlyOwner {
        crossDomainMsgSender = _crossDomainMsgSender;
    }
}
