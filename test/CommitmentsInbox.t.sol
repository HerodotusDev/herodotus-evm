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
    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external {}

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

contract CommitmentsInbox_Test is Test {
    EOA private relayer;
    EOA private owner;
    WETHMock private collateral;

    IHeadersProcessor private headersProcessor;
    MsgSignerMock private msgSigner;

    CommitmentsInbox private commitmentsInbox;

    constructor() {
        relayer = new EOA();
        owner = new EOA();

        collateral = new WETHMock();
        headersProcessor = new HeadersProcessorMock();
        msgSigner = new MsgSignerMock();

        commitmentsInbox = new CommitmentsInbox(headersProcessor, msgSigner, IERC20(address(collateral)), 0, address(owner), address(0));
    }

    function test_receiveOptimisticMessage() public {
        bytes memory signature = "0x";
        commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);
    }
}
