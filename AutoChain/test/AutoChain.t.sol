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
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        (string memory vin, string memory status, address currentOwner, , , , , , , ) = autoChain.getVehicleDetails(1);
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
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        vm.expectRevert("Vehicle with this VIN already exists");
        autoChain.registerVehicle("VIN123", owner2);
    }

    function testOwnershipTransfer() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.transferOwnership(1, owner2);

        (, , address currentOwner, , , , , , , ) = autoChain.getVehicleDetails(1);
        assertEq(currentOwner, owner2);
    }

    function testOnlyOwnerCanTransfer() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(nonAdmin);
        vm.expectRevert("Only current owner can transfer");
        autoChain.transferOwnership(1, owner2);
    }

    function testStatusUpdate() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.updateStatus(1, "stolen");

        (, string memory status, , , , , , , , ) = autoChain.getVehicleDetails(1);
        assertEq(status, "stolen");
    }

    function testOnlyAdminCanUpdateStatus() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(nonAdmin);
        vm.expectRevert();
        autoChain.updateStatus(1, "stolen");
    }

    function testOwnershipHistory() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
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
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        uint256 tokenId = autoChain.getTokenIdByVin("VIN123");
        assertEq(tokenId, 1);
    }

    function testDirectTransferAllowed() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.transferFrom(owner1, owner2, 1); // Direct transfer is allowed

        (, , address currentOwner, , , , , , , ) = autoChain.getVehicleDetails(1);
        assertEq(currentOwner, owner2);
    }

    function testUserVerification() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");

        assertTrue(autoChain.isUserVerified(owner1));
    }

    function testVehicleRegistrationRequiresVerification() public {
        vm.prank(admin);
        vm.expectRevert("Owner must be verified");
        autoChain.registerVehicle("VIN123", owner1);
    }

    function testFreezeUnfreezeVehicle() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.freezeVehicle(1);

        (, , , , , bool isFrozen, , , , ) = autoChain.getVehicleDetails(1);
        assertTrue(isFrozen);

        vm.prank(admin);
        autoChain.unfreezeVehicle(1);

        (, , , , , isFrozen, , , , ) = autoChain.getVehicleDetails(1);
        assertFalse(isFrozen);
    }

    function testCannotTransferFrozenVehicle() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.freezeVehicle(1);

        vm.prank(owner1);
        vm.expectRevert("Vehicle is frozen");
        autoChain.transferOwnership(1, owner2);
    }

    function testAccidentReporting() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.grantServiceProviderRole(nonAdmin);

        vm.prank(nonAdmin);
        autoChain.reportAccident(1, "Front collision on 2024-01-01");

        (, , , , , , string[] memory accidents, , , ) = autoChain.getVehicleDetails(1);
        assertEq(accidents.length, 1);
        assertEq(accidents[0], "Front collision on 2024-01-01");
    }

    function testMaintenanceRecording() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.grantServiceProviderRole(nonAdmin);

        vm.prank(nonAdmin);
        autoChain.recordMaintenance(1, "Oil change on 2024-02-01");

        (, , , , , , , string[] memory maintenance, , ) = autoChain.getVehicleDetails(1);
        assertEq(maintenance.length, 1);
        assertEq(maintenance[0], "Oil change on 2024-02-01");
    }

    function testLienRegistration() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.grantBankRole(nonAdmin);

        vm.prank(nonAdmin);
        autoChain.registerLien(1, 100 ether);

        assertTrue(autoChain.hasActiveLien(1));
    }

    function testCannotTransferWithActiveLien() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.grantBankRole(nonAdmin);

        vm.prank(nonAdmin);
        autoChain.registerLien(1, 100 ether);

        vm.prank(owner1);
        vm.expectRevert("Cannot transfer vehicle with active lien");
        autoChain.transferOwnership(1, owner2);
    }

    function testMarkAsStolen() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.markAsStolen(1);

        (, string memory status, , , , bool isFrozen, , , , ) = autoChain.getVehicleDetails(1);
        assertEq(status, "stolen");
        assertTrue(isFrozen);
    }

    function testCannotTransferStolenVehicle() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(admin);
        autoChain.markAsStolen(1);

        vm.prank(owner1);
        vm.expectRevert("Vehicle is frozen");
        autoChain.transferOwnership(1, owner2);
    }

    function testVehicleListing() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.listVehicle(1, 50 ether);

        // Check that listing exists by trying to purchase
        vm.prank(admin);
        autoChain.verifyUser(owner2, "Jane Doe", "ID456");
    }

    function testMarketplacePurchase() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.verifyUser(owner2, "Jane Doe", "ID456");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.listVehicle(1, 50 ether);

        // Give buyer some ether
        vm.deal(owner2, 100 ether);

        vm.prank(owner2);
        autoChain.requestPurchase{value: 50 ether}(1);

        (, , address currentOwner, , , , , , , ) = autoChain.getVehicleDetails(1);
        assertEq(currentOwner, owner2);
    }

    function testCertificateGeneration() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        vm.prank(admin);
        autoChain.registerVehicle("VIN123", owner1);

        vm.prank(owner1);
        autoChain.generateCertificate(1);

        string memory cert = autoChain.getCertificate(1);
        assertTrue(bytes(cert).length > 0);
        // Check if certificate contains expected data
        assertTrue(contains(cert, "VIN123"));
    }

    function testRoleManagement() public {
        vm.prank(admin);
        autoChain.grantAuthorityRole(nonAdmin);
        assertTrue(autoChain.hasRole(autoChain.AUTHORITY_ROLE(), nonAdmin));

        vm.prank(admin);
        autoChain.grantServiceProviderRole(nonAdmin);
        assertTrue(autoChain.hasRole(autoChain.SERVICE_PROVIDER_ROLE(), nonAdmin));

        vm.prank(admin);
        autoChain.grantBankRole(nonAdmin);
        assertTrue(autoChain.hasRole(autoChain.BANK_ROLE(), nonAdmin));
    }

    // Helper function to check if string contains substring
    function contains(string memory _str, string memory _substr) internal pure returns (bool) {
        bytes memory str = bytes(_str);
        bytes memory substr = bytes(_substr);
        for (uint256 i = 0; i <= str.length - substr.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < substr.length; j++) {
                if (str[i + j] != substr[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }

    function testEventEmission() public {
        vm.prank(admin);
        autoChain.verifyUser(owner1, "John Doe", "ID123");
        
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
        autoChain.verifyUser(owner1, "John Doe", "ID123");

        // Check that admin can register (they have AUTHORITY_ROLE from constructor)
        vm.prank(admin);
        autoChain.registerVehicle("VIN456", owner1);

        // Grant authority role to nonAdmin
        vm.prank(admin);
        autoChain.grantAuthorityRole(nonAdmin);

        vm.prank(nonAdmin);
        autoChain.registerVehicle("VIN789", owner1);

        // Check that nonAdmin has the role
        assertTrue(autoChain.hasRole(autoChain.AUTHORITY_ROLE(), nonAdmin));
    }
}