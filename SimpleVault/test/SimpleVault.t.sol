// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SimpleVault} from "../src/SimpleVault.sol";

contract SimpleVaultTest is Test {
    SimpleVault vault;
    address user1 = address(1);

    function setUp() public {
        vault = new SimpleVault();
    }

    function testDepositUpdatesBalance() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vault.deposit{value: 0.5 ether}();
        assertEq(vault.balances(user1), 0.5 ether);
    }

    function testWithdrawTransfersETH() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vault.deposit{value: 0.5 ether}();
        uint256 balanceBefore = user1.balance;
        vm.prank(user1);
        vault.withdraw(0.3 ether);
        uint256 balanceAfter = user1.balance;
        assertEq(balanceAfter - balanceBefore, 0.3 ether);
        assertEq(vault.balances(user1), 0.2 ether);
    }

    function testWithdrawWithoutBalanceReverts() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        vault.withdraw(0.1 ether);
    }
}