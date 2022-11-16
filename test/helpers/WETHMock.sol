//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/erc20/ERC20.sol";

contract WETHMock is ERC20 {
    constructor() ERC20("MockWETH", "WETH") {}

    function mint() external payable {
        _mint(msg.sender, msg.value);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}