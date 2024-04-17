// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRuneRC20 is IERC20 {
    function release(address to, uint256 amount, uint256 chainId) external;

    function relay(address from, uint256 amount, uint256 chainId) external;
}
