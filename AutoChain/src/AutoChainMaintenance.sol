// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutoChainCore.sol";

contract AutoChainMaintenance is AutoChainCore {
    bytes32 public constant SERVICE_PROVIDER_ROLE = keccak256("SERVICE_PROVIDER_ROLE");

    struct MaintenanceRecord {
        bytes32 recordType; // "accident" or "maintenance"
        bytes32 description;
        address provider;
        uint256 timestamp;
    }

    mapping(uint256 => MaintenanceRecord[]) public maintenanceRecords;

    event RecordAdded(uint256 indexed tokenId, bytes32 recordType, bytes32 description, address provider);

    constructor() {
        _grantRole(SERVICE_PROVIDER_ROLE, msg.sender);
    }

    // Add accident report
    function reportAccident(uint256 tokenId, bytes32 description) public onlyRole(SERVICE_PROVIDER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        require(description != bytes32(0), "Description cannot be empty");

        maintenanceRecords[tokenId].push(MaintenanceRecord(
            keccak256("accident"),
            description,
            msg.sender,
            block.timestamp
        ));

        emit RecordAdded(tokenId, keccak256("accident"), description, msg.sender);
    }

    // Add maintenance record
    function recordMaintenance(uint256 tokenId, bytes32 description) public onlyRole(SERVICE_PROVIDER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        require(description != bytes32(0), "Description cannot be empty");

        maintenanceRecords[tokenId].push(MaintenanceRecord(
            keccak256("maintenance"),
            description,
            msg.sender,
            block.timestamp
        ));

        emit RecordAdded(tokenId, keccak256("maintenance"), description, msg.sender);
    }

    // Get maintenance records
    function getMaintenanceRecords(uint256 tokenId) public view returns (MaintenanceRecord[] memory) {
        return maintenanceRecords[tokenId];
    }

    // Get record count
    function getRecordCount(uint256 tokenId) public view returns (uint256) {
        return maintenanceRecords[tokenId].length;
    }

    // Grant service provider role
    function grantServiceProviderRole(address account) public onlyOwner {
        grantRole(SERVICE_PROVIDER_ROLE, account);
    }
}