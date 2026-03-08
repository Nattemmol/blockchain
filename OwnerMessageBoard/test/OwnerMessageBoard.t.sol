// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {OwnerMessageBoard} from "../src/OwnerMessageBoard.sol";

contract OwnerMessageBoardTest is Test {
    OwnerMessageBoard board;
    address owner = address(this); // since deployed by test
    address nonOwner = address(1);

    function setUp() public {
        board = new OwnerMessageBoard();
    }

    function testOwnerCanUpdate() public {
        board.updateMessage("Hello World");
        assertEq(board.getMessage(), "Hello World");
    }

    function testNonOwnerCannotUpdate() public {
        vm.prank(nonOwner);
        vm.expectRevert("Not the owner");
        board.updateMessage("Unauthorized");
    }

    function testEventEmitted() public {
        vm.expectEmit(true, true, true, true);
        emit OwnerMessageBoard.MessageUpdated("Test Message");
        board.updateMessage("Test Message");
    }
}