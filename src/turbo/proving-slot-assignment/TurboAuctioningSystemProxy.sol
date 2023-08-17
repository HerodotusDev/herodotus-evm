// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TurboAuctioningSystemProxy is ERC1967Proxy {
    constructor(address _implementation) ERC1967Proxy(_implementation, "")  {}
}