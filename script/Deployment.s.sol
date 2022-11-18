// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

import {CommitmentsInbox} from "../src/CommitmentsInbox.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHeadersProcessor} from "../src/interfaces/IHeadersProcessor.sol";
import {IMsgSigner} from "../src/interfaces/IMsgSigner.sol";

contract Deployment is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CommitmentsInbox commitmentsInbox = new CommitmentsInbox(IHeadersProcessor(address(0)), IMsgSigner(address(0)), IERC20(address(0)), 0, address(0), address(0));
        vm.stopBroadcast();
    }
}
