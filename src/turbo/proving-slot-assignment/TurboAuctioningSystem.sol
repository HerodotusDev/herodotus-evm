// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract TurboAuctioningSystem is AccessControl {
    using SafeERC20 for IERC20;

    struct WithdrawalRequest {
        uint256 amount;
        uint256 timestamp;
        address recipient;
    }

    struct SlotAssignmentBid {
        uint256 slotId;
        uint256 amount;
        address assignee;
        bytes signature;
        // TODO add callback signature?
    }

    event SlotAssigned(uint256 slotId, address assignee, uint256 winningBidAmount);

    bytes32 constant public AUCTION_OPERATOR_ROLE = "AUCTION_OPERATOR_ROLE";

    uint256 public immutable deploymentTimestamp;
    uint256 public immutable slotDurationSeconds;
    IERC20 public immutable biddingToken;
    uint256 public immutable withdrawalDelaySeconds;

    // State channel deposits
    mapping(address => uint256) public biddingStateChannelDeposit;

    // State channel withdrawals requests
    uint256 public withdrawalRequestsCount;
    mapping (uint256 => WithdrawalRequest) public withdrawalRequests;

    // Slot assignments
    uint256 public slotAssignmentsCount;
    uint256 public lastAssignedSlotId;
    mapping (uint256 => address) public slotAssignments;

    constructor(uint256 _slotDurationSeconds, IERC20 _biddingToken, uint256 _withdrawalDelaySeconds) {
        deploymentTimestamp = block.timestamp;
        slotDurationSeconds = _slotDurationSeconds;
        biddingToken = _biddingToken;
        withdrawalDelaySeconds = _withdrawalDelaySeconds;
        _setupRole(AUCTION_OPERATOR_ROLE, msg.sender);
    }

    function currentSlotId() public view returns(uint256) {
        return (block.timestamp - deploymentTimestamp) / slotDurationSeconds;
    }

    function getCurrentAssignee() public view returns(address) {
        address assignee = slotAssignments[currentSlotId()];
        if(assignee != address(0)) {
            return assignee;
        }
        return slotAssignments[lastAssignedSlotId];
    }

    function getMissedSlotsCount() public view returns(uint256) {
        return currentSlotId() - slotAssignmentsCount;
    }

    function depositToStateChannel(uint256 amount) external {
        biddingToken.safeTransferFrom(msg.sender, address(this), amount);
        biddingStateChannelDeposit[msg.sender] += amount;
    }

    function initiateWithdrawal(uint256 amount, address recipient) external {
        require(biddingStateChannelDeposit[msg.sender] >= amount, "Not enough funds");
        biddingStateChannelDeposit[msg.sender] -= amount;
        withdrawalRequests[withdrawalRequestsCount] = WithdrawalRequest(amount, block.timestamp, recipient);
        withdrawalRequestsCount++;
    }

    function withdraw(uint256 withdrawalRequestId) external {
        WithdrawalRequest storage request = withdrawalRequests[withdrawalRequestId];
        require(request.timestamp + withdrawalDelaySeconds <= block.timestamp, "Withdrawal delay not passed");
        require(request.recipient == msg.sender, "Only recipient can withdraw");
        biddingToken.safeTransfer(msg.sender, request.amount);
        delete withdrawalRequests[withdrawalRequestId];
    }

    // The assumption is that all provided bids are for the same slot and are ordered DESC by highest bid.
    function settleBids(SlotAssignmentBid[] calldata bids) external {
        require(hasRole(AUCTION_OPERATOR_ROLE, msg.sender), "Only auction operator can settle bids");
        require(bids.length > 0, "ERR_NO_BIDS_PROVIDED");

        uint256 auctionedSlotId = bids[0].slotId;
        uint256 winningBidAmount = bids[0].amount;

        for(uint256 i = 0; i < bids.length; i++) {
            SlotAssignmentBid memory bid = bids[i];
            require(bid.slotId == auctionedSlotId, "ERR_BID_FOR_DIFFERENT_SLOTS");
            require(bid.amount <= winningBidAmount, "ERR_BIDS_NOT_ORDERED_DESC");
        }

        // Ensure valid signature
        bytes32 messageHash = keccak256(abi.encodePacked(auctionedSlotId, winningBidAmount, bids[0].assignee));
        address bidder = ECDSA.recover(messageHash, bids[0].signature);

        // Ensure winner has enough funds
        require(biddingStateChannelDeposit[bidder] >= winningBidAmount, "ERR_NOT_ENOUGH_FUNDS");

        // Transfer funds from winner to contract
        biddingToken.safeTransferFrom(bidder, address(this), winningBidAmount); // TODO should be redistribution fund

        // Assign slot to winner
        slotAssignments[auctionedSlotId] = bids[0].assignee;
        slotAssignmentsCount++;
        lastAssignedSlotId = auctionedSlotId;

        emit SlotAssigned(auctionedSlotId, bids[0].assignee, winningBidAmount);
    }
}