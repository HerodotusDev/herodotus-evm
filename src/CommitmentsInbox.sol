// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ICommitmentsInbox} from "./interfaces/ICommitmentsInbox.sol";
import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {IMsgSigner} from "./interfaces/IMsgSigner.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CommitmentsInbox is ICommitmentsInbox, Ownable {
    address public immutable crossDomainMsgSender;
    IHeadersProcessor public immutable headersProcessor;
    IMsgSigner public immutable optimisticSigner;

    IERC20 public immutable stakingAsset;
    uint256 public stakingRequirement;

    constructor(
        IHeadersProcessor _headersProcessor,
        IMsgSigner _optimisticSigner,
        IERC20 _stakingAsset,
        uint256 _stakingRequirement,
        address _owner,
        address _crossDomainMsgSender
    ) {
        Ownable._transferOwnership(_owner);
        optimisticSigner = _optimisticSigner;
        headersProcessor = _headersProcessor;
        stakingAsset = _stakingAsset;
        stakingRequirement = _stakingRequirement;
        crossDomainMsgSender = _crossDomainMsgSender;
    }

    function receiveCrossdomainMessage(
        bytes32 parentHash,
        uint256 blockNumber,
        address relayerPenaltyRecipient
    ) external {}

    function receiveOptimisticMessage(
        bytes32 parentHash,
        uint256 blockNumber,
        bytes calldata signature
    ) external {
        bytes32 msgHash = keccak256(abi.encode(parentHash, blockNumber, address(this)));
        optimisticSigner.verify(msgHash, signature);
    }
}
