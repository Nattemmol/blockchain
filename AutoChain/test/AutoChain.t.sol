// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {AutoChain} from "../src/AutoChain.sol";

contract AutoChainTest is Test {
    AutoChain autoChain;
    address admin = address(1);
    address owner1 = address(2);
    address owner2 = address(3);
    address nonAdmin = address(4);

    function setUp() public {
        vm.prank(admin);
        autoChain = new AutoChain();
    }

    function testVehicleRegistration() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        (string memory vin, string memory status, address currentOwner, , ) = autoChain.getVehicleDetails(1);
        assertEq(vin, "VIN123");
        assertEq(status, "active");
        assertEq(currentOwner, owner1);
    }

    function testOnlyAdminCanRegister() public {
        vm.prank(nonAdmin);
        vm.expectRevert();
        autoChain.registerVehicle("VIN123", owner1);
    }

    function testDuplicateVinRegistration() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        vm.expectRevert("Vehicle with this VIN already exists");
        autoChain.registerVehicle("VIN123", owner2);
    }

    function testOwnershipTransfer() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.transferOwnership(1, owner2);

        (, , address currentOwner, , ) = autoChain.getVehicleDetails(1);
        assertEq(currentOwner, owner2);
    }

    function testOnlyOwnerCanTransfer() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(nonAdmin);
        vm.expectRevert("Only current owner can transfer");
        autoChain.transferOwnership(1, owner2);
    }

    function testStatusUpdate() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.updateStatus(1, "stolen");

        (, string memory status, , , ) = autoChain.getVehicleDetails(1);
        assertEq(status, "stolen");
    }

    function testOnlyAdminCanUpdateStatus() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(nonAdmin);
        vm.expectRevert();
        autoChain.updateStatus(1, "stolen");
    }

    function testOwnershipHistory() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.transferOwnership(1, owner2);

        (address[] memory owners, uint256[] memory timestamps) = autoChain.getOwnershipHistory(1);
        assertEq(owners.length, 2);
        assertEq(owners[0], owner1);
        assertEq(owners[1], owner2);
        assertTrue(timestamps[1] >= timestamps[0]);
    }

    function testGetTokenIdByVin() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        uint256 tokenId = autoChain.getTokenIdByVin("VIN123");
        assertEq(tokenId, 1);
    }

    function testDirectTransferAllowed() public {
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.transferFrom(owner1, owner2, 1); // Direct transfer is allowed

        (, , address currentOwner, , ) = autoChain.getVehicleDetails(1);
        assertEq(currentOwner, owner2);
    }

    function testEventEmission() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit AutoChain.VehicleRegistered(1, "VIN123", owner1);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        vm.expectEmit(true, true, true, false);
        emit AutoChain.OwnershipTransferred(1, owner1, owner2);
        autoChain.transferOwnership(1, owner2);

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit AutoChain.StatusUpdated(1, "stolen");
        autoChain.updateStatus(1, "stolen");
    }

    function testAdminRoleManagement() public {
        vm.prank(admin);
        autoChain.grantAdminRole(nonAdmin);

        vm.prank(nonAdmin);
        autoChain.registerVehicle("VIN456", owner1);

        vm.prank(admin);
        autoChain.revokeAdminRole(nonAdmin);

        vm.prank(nonAdmin);
        vm.expectRevert();
        autoChain.registerVehicle("VIN789", owner1);
    }
}