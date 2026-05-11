/*2.Testing (inside `test/`)

Write a test file for the contract.

Your tests must verify:

* A user can deposit ETH successfully.
* The balance updates correctly.
* A user cannot withdraw more than their balance.
* After withdrawal, the balance updates correctly.
* The contract total balance reflects deposits.

Bonus: Test multiple users depositing and withdrawing.*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SavingsBank} from "../src/SavingsBank.sol";

contract SavingsBankTest is Test {
    SavingsBank savingsBank;

    function setUp() public {
        savingsBank = new SavingsBank();
    }

    function testDeposit() public {
        savingsBank.deposit({value: 100});
        assert(savingsBank.getBalance() == 100);
        assert(savingsBank.getTotalBalance() == 100);
    }

    function testWithdraw() public {
        savingsBank.deposit({value: 100});
        savingsBank.withdraw(50);
        assert(savingsBank.getBalance() == 50);
        assert(savingsBank.getTotalBalance() == 50);
    }


    function testWithdrawMoreThanBalance() public {
        savingsBank.deposit({value: 100});
        vm.expectRevert("Insufficient balance");
        savingsBank.withdraw(150);
    }

    function testMultipleUsers() public {
        // User 1 deposits
        vm.prank(address(0x1));
        savingsBank.deposit({value: 100});

        // User 2 deposits
        vm.prank(address(0x2));
        savingsBank.deposit({value: 200});

        // Check balances
        vm.prank(address(0x1));
        assert(savingsBank.getBalance() == 100);
        
        vm.prank(address(0x2));
        assert(savingsBank.getBalance() == 200);

        // Check total balance
        assert(savingsBank.getTotalBalance() == 300);

        // User 1 withdraws
        vm.prank(address(0x1));
        savingsBank.withdraw(50);
        
        // Check balances after withdrawal
        vm.prank(address(0x1));
        assert(savingsBank.getBalance() == 50);
        
        vm.prank(address(0x2));
        assert(savingsBank.getBalance() == 200);

        // Check total balance after withdrawal
        assert(savingsBank.getTotalBalance() == 250);
    }
}