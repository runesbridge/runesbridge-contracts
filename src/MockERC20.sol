// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(_msgSender(), 1000000 * 10 ** 18);
    }

    function mint() external {
        _mint(_msgSender(), 1000000 * 10 ** 18);
    }

    receive() external payable {
        _mint(_msgSender(), 1000000 * 10 ** 18);
    }
}
