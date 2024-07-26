// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ISharpProofsAggregator} from "./ISharpProofsAggregator.sol";

interface ISharpProofsAggregatorsFactory {
    function aggregatorsById(uint256 aggregatorId) external returns (address);
}
