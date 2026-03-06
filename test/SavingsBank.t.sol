// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SavingsBank} from "../src/SavingsBank.sol";

contract SavingsBankTest is Test {
    SavingsBank savingsBank;
    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        savingsBank = new SavingsBank();
    }

    function testDeposit() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        savingsBank.deposit{value: 0.1 ether}();
        assertEq(savingsBank.balances(user1), 0.1 ether);
        assertEq(savingsBank.getTotalBalance(), 0.1 ether);
    }

    function testDepositBelowMinimum() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Minimum deposit is 0.01 ETH");
        savingsBank.deposit{value: 0.005 ether}();
    }

    function testWithdraw() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        savingsBank.deposit{value: 0.1 ether}();
        vm.prank(user1);
        savingsBank.withdraw(0.05 ether);
        assertEq(savingsBank.balances(user1), 0.05 ether);
        assertEq(savingsBank.getTotalBalance(), 0.05 ether);
    }

    function testWithdrawInsufficientBalance() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        savingsBank.deposit{value: 0.1 ether}();
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        savingsBank.withdraw(0.2 ether);
    }

    function testMultipleUsers() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.prank(user1);
        savingsBank.deposit{value: 0.1 ether}();
        vm.prank(user2);
        savingsBank.deposit{value: 0.2 ether}();
        assertEq(savingsBank.balances(user1), 0.1 ether);
        assertEq(savingsBank.balances(user2), 0.2 ether);
        assertEq(savingsBank.getTotalBalance(), 0.3 ether);
        vm.prank(user1);
        savingsBank.withdraw(0.05 ether);
        assertEq(savingsBank.balances(user1), 0.05 ether);
        assertEq(savingsBank.getTotalBalance(), 0.25 ether);
    }

    function testCheckBalance() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        savingsBank.deposit{value: 0.1 ether}();
        vm.prank(user1);
        uint256 balance = savingsBank.checkBalance();
        assertEq(balance, 0.1 ether);
    }
}