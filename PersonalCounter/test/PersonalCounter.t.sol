// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PersonalCounter} from "../src/PersonalCounter.sol";

contract PersonalCounterTest is Test {
    PersonalCounter counter;
    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        counter = new PersonalCounter();
    }

    function testIncrement() public {
        vm.startPrank(user1);
        counter.increment();
        counter.increment();
        vm.stopPrank();
        assertEq(counter.getCounter(user1), 2);
    }

    function testReset() public {
        vm.startPrank(user1);
        counter.increment();
        counter.increment();
        vm.stopPrank();
        assertEq(counter.getCounter(user1), 2);
        vm.prank(user1);
        counter.reset();
        assertEq(counter.getCounter(user1), 0);
    }

    function testCannotResetAnotherUser() public {
        vm.startPrank(user1);
        counter.increment();
        counter.increment();
        vm.stopPrank();
        assertEq(counter.getCounter(user1), 2);
        vm.prank(user2);
        counter.reset(); // This resets user2's counter, not user1's
        assertEq(counter.getCounter(user1), 2); // user1's should remain
        assertEq(counter.getCounter(user2), 0); // user2's is 0
    }
}