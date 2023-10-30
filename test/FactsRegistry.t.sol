// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";


import {EOA} from "./helpers/EOA.sol";
import {HeadersProcessor} from "../src/core/HeadersProcessor.sol";
import {FactsRegistry} from "../src/core/FactsRegistry.sol";

import {MessagesInbox} from "../src/core/MessagesInbox.sol";

uint256 constant DEFAULT_TREE_ID = 0;

contract FactsRegistry_Test is Test {}
