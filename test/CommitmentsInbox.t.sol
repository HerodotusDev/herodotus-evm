// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {EOA} from "./helpers/EOA.sol";
import {WETHMock} from "./helpers/WETHMock.sol";

import {CommitmentsInbox} from "../src/CommitmentsInbox.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHeadersProcessor} from "../src/interfaces/IHeadersProcessor.sol";
import {IMsgSigner} from "../src/interfaces/IMsgSigner.sol";

import {Secp256k1MsgSigner} from "../src/msg-signers/Secp256k1MsgSigner.sol";

contract HeadersProcessorMock is IHeadersProcessor {
    mapping(uint256 => bytes32) public parentHashes;

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external {
        parentHashes[blockNumber] = parentHash;
    }

    function receivedParentHashes(uint256 blockNumber) external view returns (bytes32) {
        return parentHashes[blockNumber];
    }
}

contract MsgSignerMock is IMsgSigner {
    function verify(bytes32 hash, bytes calldata sig) external view {}

    function signingKey() external pure returns (bytes32) {
        return bytes32(0);
    }
}

contract CommitmentsInbox_OptimiticRelaying_Test is Test {
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

        commitmentsInbox = new CommitmentsInbox(msgSigner, IERC20(address(collateral)), 0, address(owner), address(0));
        commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
    }

    function test_receiveOptimisticMessage() public {
        bytes memory signature = "0x";
        commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);
        assertEq(headersProcessor.parentHashes(1), bytes32(uint256(1)));
    }
}

contract CommitmentsInbox_CrossdomainMessaging_Test is Test {
    EOA private relayer;
    EOA private owner;
    EOA private crossdomainDelivery;
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

        commitmentsInbox = new CommitmentsInbox(msgSigner, IERC20(address(collateral)), 0, address(owner), address(crossdomainDelivery));
        commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
    }

    function test_fail_receiveCrossdomainMessage_notCrossdomainMsgSender() public {
        vm.prank(address(1));
        vm.expectRevert();
        commitmentsInbox.receiveCrossdomainMessage(bytes32(uint256(1)), 1, address(0));
    }

    function test_receiveCrossdomainMessage_messageSets() public {
        vm.prank(address(crossdomainDelivery));
        commitmentsInbox.receiveCrossdomainMessage(bytes32(uint256(1)), 1, address(0));
        assertEq(headersProcessor.parentHashes(1), bytes32(uint256(1)));
    }

    function test_receiveCrossdomainMessage_fraudDetection() public {
        /// Fraudaulent relayer behaviour
        bytes memory signature = "0x";
        commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);

        /// Resolution
        vm.prank(address(crossdomainDelivery));
        // vm.expectEmit(false, false, false, true); TODO fix this
        commitmentsInbox.receiveCrossdomainMessage(bytes32(uint256(2)), 1, address(0));
        assertEq(headersProcessor.parentHashes(1), bytes32(uint256(2)));
    }
}

contract CommitmentsInbox_Staking_Test is Test {
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

        commitmentsInbox = new CommitmentsInbox(msgSigner, IERC20(address(collateral)), _collateralRequirement, address(owner), address(0));
        commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
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

    function test_fail_receiveOptimisticMessage_notStaked() public {
        bytes memory signature = "0x";
        vm.expectRevert();
        commitmentsInbox.receiveOptimisticMessage(bytes32(uint256(1)), 1, signature);
    }

    function _stake(bytes memory signature) internal {
        collateral.mint(address(relayer), _collateralRequirement);
        vm.startPrank(address(relayer));
        collateral.approve(address(commitmentsInbox), type(uint256).max);
        commitmentsInbox.stake(signature);
        vm.stopPrank();
    }
}

contract CommitmentsInbox_Signing_Test is Test {
    using Strings for uint256;

    CommitmentsInbox private commitmentsInbox;
    Secp256k1MsgSigner private msgSigner;

    EOA private relayer;
    EOA private owner;
    WETHMock private collateral;

    HeadersProcessorMock private headersProcessor;

    constructor() {
        string[] memory getAddress_inputs = new string[](2);
        getAddress_inputs[0] = "node";
        getAddress_inputs[1] = "./helpers/fetch_account_nonce.js";
        bytes memory result = vm.ffi(getAddress_inputs);

        (address account, ) = abi.decode(result, (address, uint256));

        relayer = new EOA();
        owner = new EOA();

        collateral = new WETHMock();
        headersProcessor = new HeadersProcessorMock();
        msgSigner = new Secp256k1MsgSigner(account, address(1));

        commitmentsInbox = new CommitmentsInbox(msgSigner, IERC20(address(collateral)), 0, address(owner), address(0));
        commitmentsInbox.initialize(IHeadersProcessor(address(headersProcessor)));
    }

    function test_receiveOptimisticMessage() public {
        bytes4 methodSelector = 0xe0eac309;
        bytes32 parentHash = 0xa95f8bec71798d9b7d8a73146aa296b92b29962401e84a9f3c679294eb5baac6;
        uint256 blockNumber = 8132837;
        address verificationContract = address(commitmentsInbox);

        string[] memory getSig_inputs = new string[](6);
        getSig_inputs[0] = "node";
        getSig_inputs[1] = "./helpers/sign_optimistic_msg.js";
        getSig_inputs[2] = uint256(uint32(methodSelector)).toHexString();
        getSig_inputs[3] = uint256(parentHash).toHexString();
        getSig_inputs[4] = blockNumber.toHexString();
        getSig_inputs[5] = uint256(uint160(verificationContract)).toHexString();
        bytes memory signature = vm.ffi(getSig_inputs);

        commitmentsInbox.receiveOptimisticMessage(parentHash, blockNumber, signature);

        assertEq(headersProcessor.receivedParentHashes(blockNumber), parentHash);
    }
}
