// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";

import {EOA} from "./helpers/EOA.sol";
import {WETHMock} from "./helpers/WETHMock.sol";

import {CommitmentsInbox} from "../src/CommitmentsInbox.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHeadersProcessor} from "../src/interfaces/IHeadersProcessor.sol";
import {IMsgSigner} from "../src/interfaces/IMsgSigner.sol";

contract HeadersProcessorMock is IHeadersProcessor {
    mapping(uint256 => bytes32) public parentHashes;

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external {
        parentHashes[blockNumber] = parentHash;
    }

    function receivedParentHashes(uint256) external view returns (bytes32) {
        return bytes32(0);
    }
}

contract MsgSignerMock is IMsgSigner {
    function verify(bytes32 hash, bytes calldata sig) external view {}

    function signingKey() external view returns (bytes32) {
        return bytes32(0);
    }
}

contract CommitmentsInbox_WithoutStaking_Test is Test {
    EOA private relayer;
    EOA private owner;
    WETHMock private collateral;

    HeadersProcessorMock private headersProcessor;
    MsgSignerMock private msgSigner;

    CommitmentsInbox private commitmentsInbox;

    constructor() {
        relayer = new EOA();
        owner = new EOA();

        collateral = new WETHMock();
        headersProcessor = new HeadersProcessorMock();
        msgSigner = new MsgSignerMock();

        commitmentsInbox = new CommitmentsInbox(IHeadersProcessor(address(headersProcessor)), msgSigner, IERC20(address(collateral)), 0, address(owner), address(0));
    }

    function test_receiveOptimisticMessage() public {
        bytes memory signature = "0x";
        commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);
        assertEq(headersProcessor.parentHashes(1), bytes32(uint256(1)));
    }
}

contract CommitmentsInbox_WithStaking_Test is Test {
    EOA private relayer;
    EOA private owner;
    WETHMock private collateral;

    HeadersProcessorMock private headersProcessor;
    MsgSignerMock private msgSigner;

    CommitmentsInbox private commitmentsInbox;

    uint256 private _collateralRequirement = 1000;

    constructor() {
        relayer = new EOA();
        owner = new EOA();

        collateral = new WETHMock();
        headersProcessor = new HeadersProcessorMock();
        msgSigner = new MsgSignerMock();

        commitmentsInbox = new CommitmentsInbox(
            IHeadersProcessor(address(headersProcessor)),
            msgSigner,
            IERC20(address(collateral)),
            _collateralRequirement,
            address(owner),
            address(0)
        );
    }

    function test_stake() public {
        bytes memory signature = "0x";
        _stake(signature);
        assertEq(collateral.balanceOf(address(commitmentsInbox)), _collateralRequirement);
    }

    function test_receiveOptimisticMessage_staked() public {
        bytes memory signature = "0x";
        _stake(signature);
        commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);
        assertEq(headersProcessor.parentHashes(1), bytes32(uint256(1)));
    }

    function fail_receiveOptimisticMessage_notStaked() public {
        bytes memory signature = "0x";
        commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);
        assertEq(headersProcessor.parentHashes(1), bytes32(uint256(1)));
    }

    function _stake(bytes memory signature) internal {
        collateral.mint(address(relayer), _collateralRequirement);
        vm.startPrank(address(relayer));
        collateral.approve(address(commitmentsInbox), type(uint256).max);
        commitmentsInbox.stake(signature);
        vm.stopPrank();
    }
}
