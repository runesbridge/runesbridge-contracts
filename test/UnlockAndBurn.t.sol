// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/RunesBridge.sol";
import "../src/UnlockAndBurn.sol";
import "../src/IUNCXTokenVesting.sol";

contract RunicChainTest is Test {
    IUNCXTokenVesting public tokenVesting =
        IUNCXTokenVesting(0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf);
    RunesBridge public runebridge =
        RunesBridge(payable(0xe91598331A36A78f7fEfe277cE7C1915DA0AfB93));
    UnlockAndBurn public contractBurn;

    uint256 public LOCK_ID = 7549;
    uint256 public NEW_LOCK_ID;

    address owner = address(0x4506663a9B53e4c79849aC8710eFeAff70955166);
    address alice = address(0x789);
    address bob = address(0xabc);

    string RPC_URL = "https://rpc.ankr.com/eth";
    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(RPC_URL);
        vm.selectFork(mainnetFork);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        vm.prank(owner);
        contractBurn = new UnlockAndBurn();
        NEW_LOCK_ID = tokenVesting.NONCE();
        vm.prank(owner);
        tokenVesting.transferLockOwnership(
            LOCK_ID,
            payable(address(contractBurn))
        );
    }

    function test_owner() public {
        address _owner = tokenVesting.LOCKS(NEW_LOCK_ID).owner;
        assertEq(_owner, address(contractBurn), "owner");
    }

    function test_unlock() public {
        uint256 currentSupply = runebridge.totalSupply();
        vm.warp(1728432001);
        uint256 totalAmount = tokenVesting.getWithdrawableShares(NEW_LOCK_ID);
        console.log("totalAmount", totalAmount);
        contractBurn.unlockAndBurn(NEW_LOCK_ID, totalAmount);
        assertEq(
            runebridge.totalSupply(),
            currentSupply - totalAmount,
            "supply"
        );
    }
}
