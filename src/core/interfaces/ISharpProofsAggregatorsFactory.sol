// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISharpProofsAggregator} from "./ISharpProofsAggregator.sol";


interface ISharpProofsAggregatorsFactory {
    function getAggregatorById(uint256 aggregatorId) external returns (address);
}