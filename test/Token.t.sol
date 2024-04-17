// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/RunesBridge.sol";

contract RunicChainTest is Test {
    IUniswapV2Router02 public V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    RunesBridge public runebridge;

    address owner = address(0x456);
    address alice = address(0x789);
    address bob = address(0xabc);

    string RPC_URL = "https://rpc.ankr.com/eth";
    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(RPC_URL);
        vm.selectFork(mainnetFork);
        vm.prank(owner);
        vm.deal(owner, 100 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        runebridge = new RunesBridge();
    }

    function test_Balance() public {
        assertEq(runebridge.balanceOf(owner), 100_000_000 ether, "balance");
    }

    function test_transfer() public {
        vm.prank(owner);
        runebridge.transfer(alice, 10 ether);
        assertEq(runebridge.balanceOf(alice), 10 ether, "balance");
    }

    function test_addLiquid() public {
        vm.startPrank(owner);

        runebridge.approve(address(V2_ROUTER), runebridge.balanceOf(owner));

        V2_ROUTER.addLiquidityETH{value: 5 ether}(
            address(runebridge),
            runebridge.balanceOf(owner),
            0,
            0,
            owner,
            block.timestamp
        );

        address pair = IUniswapV2Factory(V2_ROUTER.factory()).getPair(
            address(runebridge),
            V2_ROUTER.WETH()
        );
        assertEq(runebridge.balanceOf(pair), 100_000_000 ether, "pair balance");
        vm.stopPrank();
    }

    function test_remveLiquid() public {
        vm.startPrank(owner);

        runebridge.approve(address(V2_ROUTER), runebridge.balanceOf(owner));

        V2_ROUTER.addLiquidityETH{value: 5 ether}(
            address(runebridge),
            runebridge.balanceOf(owner),
            0,
            0,
            owner,
            block.timestamp
        );

        address pair = IUniswapV2Factory(V2_ROUTER.factory()).getPair(
            address(runebridge),
            V2_ROUTER.WETH()
        );
        assertEq(runebridge.balanceOf(pair), 100_000_000 ether, "pair balance");

        IERC20(pair).approve(address(V2_ROUTER), type(uint256).max);
        V2_ROUTER.removeLiquidityETH(
            address(runebridge),
            IERC20(pair).balanceOf(owner),
            0,
            0,
            owner,
            block.timestamp
        );

        vm.stopPrank();
    }

    function test_BuyWhenNotOpenTrading() public {
        vm.startPrank(owner);

        runebridge.approve(address(V2_ROUTER), runebridge.balanceOf(owner));

        V2_ROUTER.addLiquidityETH{value: 5 ether}(
            address(runebridge),
            runebridge.balanceOf(owner),
            0,
            0,
            owner,
            block.timestamp
        );

        address pair = IUniswapV2Factory(V2_ROUTER.factory()).getPair(
            address(runebridge),
            V2_ROUTER.WETH()
        );
        assertEq(runebridge.balanceOf(pair), 100_000_000 ether, "pair balance");
        vm.stopPrank();

        vm.startPrank(alice);

        address[] memory path = new address[](2);
        path[0] = V2_ROUTER.WETH();
        path[1] = address(runebridge);

        vm.expectRevert("UniswapV2: TRANSFER_FAILED");

        V2_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: 1 ether
        }(0, path, alice, block.timestamp);
    }

    function test_whenOpenTrading() public {
        vm.startPrank(owner);

        runebridge.openTrading();

        V2_ROUTER.addLiquidityETH{value: 5 ether}(
            address(runebridge),
            runebridge.balanceOf(owner),
            0,
            0,
            owner,
            block.timestamp
        );

        address pair = IUniswapV2Factory(V2_ROUTER.factory()).getPair(
            address(runebridge),
            V2_ROUTER.WETH()
        );
        assertEq(runebridge.balanceOf(pair), 100_000_000 ether, "pair balance");
        vm.stopPrank();

        vm.startPrank(alice);

        address[] memory path = new address[](2);
        path[0] = V2_ROUTER.WETH();
        path[1] = address(runebridge);

        vm.roll(block.number + 3);

        V2_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: 0.01 ether
        }(0, path, alice, block.timestamp);

        assertGt(runebridge.balanceOf(alice), 0, "alice balance");
    }

    function test_whenOpenTradingAndSwap() public {
        vm.startPrank(owner);

        runebridge.openTrading();
        runebridge.disableLimits();

        V2_ROUTER.addLiquidityETH{value: 5 ether}(
            address(runebridge),
            runebridge.balanceOf(owner),
            0,
            0,
            owner,
            block.timestamp
        );

        address pair = IUniswapV2Factory(V2_ROUTER.factory()).getPair(
            V2_ROUTER.WETH(),
            address(runebridge)
        );
        assertEq(runebridge.balanceOf(pair), 100_000_000 ether, "pair balance");
        assertGt(IERC20(V2_ROUTER.WETH()).balanceOf(pair), 0, "pair balance");
        vm.stopPrank();

        vm.startPrank(alice);

        address[] memory path = new address[](2);
        path[0] = V2_ROUTER.WETH();
        path[1] = address(runebridge);

        address[] memory pathSell = new address[](2);
        pathSell[0] = address(runebridge);
        pathSell[1] = V2_ROUTER.WETH();

        vm.roll(block.number + 3);

        runebridge.approve(address(V2_ROUTER), type(uint256).max);

        for (uint i = 0; i < 5; i++) {
            V2_ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: 0.01 ether
            }(0, path, alice, block.timestamp);

            V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
                runebridge.balanceOf(alice),
                0,
                pathSell,
                alice,
                block.timestamp
            );
        }

        assertGt(owner.balance, 0, "owner balance");
        vm.stopPrank();
        vm.startPrank(owner);

        uint256 lpBalance = IERC20(pair).balanceOf(owner);
        assertGt(lpBalance, 0, "lp balance");
        IERC20(pair).approve(address(V2_ROUTER), type(uint256).max);

        V2_ROUTER.removeLiquidityETH(
            address(runebridge),
            IERC20(pair).balanceOf(owner),
            0,
            0,
            owner,
            block.timestamp
        );
    }

    function test_rescueETH() public {
        vm.startPrank(owner);
        (bool sent, ) = payable(address(runebridge)).call{value: 1 ether}("");
        require(sent, "send ETH test failed");
        assertEq(address(runebridge).balance, 1 ether);
        uint256 balanceBefore = owner.balance;
        runebridge.rescueETH(0);
        assertEq(owner.balance, balanceBefore + 1 ether);
        assertEq(address(runebridge).balance, 0);
    }
}
