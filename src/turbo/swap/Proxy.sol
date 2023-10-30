// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TurboSwapProxy is ERC1967Proxy {
    constructor(address _implementation) ERC1967Proxy(_implementation, "")  {}
}