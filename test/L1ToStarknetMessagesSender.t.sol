// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {L1ToStarknetMessagesSender} from "../src/core/x-rollup-messaging/outbox/L1ToStarknetMessagesSender.sol";
import {IStarknetCore} from "../src/core/x-rollup-messaging/interfaces/IStarknetCore.sol";
import {IParentHashFetcher} from "../src/core/x-rollup-messaging/interfaces/IParentHashFetcher.sol";

contract MockParentHashFetcher {
    function fetchParentHash(bytes memory ctx) external pure returns (uint256, bytes32) {
        uint256 prevBlock = abi.decode(ctx, (uint256));
        return (prevBlock, bytes32(uint256(2748)));
    }

    function chainId() external pure returns (uint256) {
        return 3;
    }
}

contract L1ToStarknetMessagesSenderTest is Test {
    L1ToStarknetMessagesSender public sender;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        MockParentHashFetcher parentHashFetcher = new MockParentHashFetcher();

        sender = new L1ToStarknetMessagesSender(
            IStarknetCore(0xE2Bb56ee936fd6433DC0F6e7e3b8365C906AA057),
            0x018c9ce7ffa88f15bd1fcda1350cb66cc5c369bc924e5dc108be1c9317298c99,
            0x70C61dd17b7207B450Cb7DeDC92C1707A07a1213,
            IParentHashFetcher(address(parentHashFetcher))
        );
    }

    function testSendExactParentHashToL2() public {
        uint256 prevBlock = block.number - 1;
        bytes memory ctx = abi.encodePacked(prevBlock);

        // Value must be greater than 0
        sender.sendExactParentHashToL2{value: 1}(ctx);
    }

    function testSendPoseidonMMRTreeToL2() public {
        // This aggregator id must exist in the factory
        uint256 aggregatorId = 1;

        uint256 mmrId = 4;

        // Value must be greater than 0
        sender.sendPoseidonMMRTreeToL2{value: 1}(aggregatorId, mmrId);
    }
}
