// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AutoChain is ERC721, Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Vehicle {
        string vin;
        string status; // e.g., "active", "stolen", "scrapped"
        address[] ownershipHistory;
        uint256[] transferTimestamps;
    }

    mapping(uint256 => Vehicle) public vehicles;
    mapping(string => bool) public vinExists; // To prevent duplicate VINs
    uint256 public nextTokenId = 1;

    event VehicleRegistered(uint256 indexed tokenId, string vin, address indexed owner);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event StatusUpdated(uint256 indexed tokenId, string newStatus);

    constructor() ERC721("AutoChain Vehicle", "AUTO") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // FR-1: Only authorized users can register vehicles
    function registerVehicle(string memory vin, address initialOwner) public onlyRole(ADMIN_ROLE) {
        require(bytes(vin).length > 0, "VIN is required");
        require(!vinExists[vin], "Vehicle with this VIN already exists"); // FR-2: Each vehicle registered only once

        uint256 tokenId = nextTokenId++;
        _mint(initialOwner, tokenId);

        vehicles[tokenId] = Vehicle({
            vin: vin,
            status: "active",
            ownershipHistory: new address[](0),
            transferTimestamps: new uint256[](0)
        });

        vehicles[tokenId].ownershipHistory.push(initialOwner);
        vehicles[tokenId].transferTimestamps.push(block.timestamp);
        vinExists[vin] = true;

        emit VehicleRegistered(tokenId, vin, initialOwner);
    }

    // FR-8: Only current owner can initiate transfer
    function transferOwnership(uint256 tokenId, address to) public {
        require(ownerOf(tokenId) == msg.sender, "Only current owner can transfer");
        require(to != address(0), "Cannot transfer to zero address");

        address from = msg.sender;
        _transfer(from, to, tokenId);

        vehicles[tokenId].ownershipHistory.push(to);
        vehicles[tokenId].transferTimestamps.push(block.timestamp);

        emit OwnershipTransferred(tokenId, from, to);
    }

    // FR-16: Authorized users can update status
    function updateStatus(uint256 tokenId, string memory newStatus) public onlyRole(ADMIN_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        require(bytes(newStatus).length > 0, "Status cannot be empty");

        vehicles[tokenId].status = newStatus;
        emit StatusUpdated(tokenId, newStatus);
    }

    // FR-18-20: Vehicle verification
    function getVehicleDetails(uint256 tokenId) public view returns (
        string memory vin,
        string memory status,
        address currentOwner,
        address[] memory history,
        uint256[] memory timestamps
    ) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        Vehicle memory v = vehicles[tokenId];
        return (v.vin, v.status, ownerOf(tokenId), v.ownershipHistory, v.transferTimestamps);
    }

    // FR-12-14: Ownership history
    function getOwnershipHistory(uint256 tokenId) public view returns (address[] memory owners, uint256[] memory timestamps) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        return (vehicles[tokenId].ownershipHistory, vehicles[tokenId].transferTimestamps);
    }

    // Utility function to get tokenId by VIN (for verification)
    function getTokenIdByVin(string memory vin) public view returns (uint256) {
        require(vinExists[vin], "VIN not found");
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (keccak256(bytes(vehicles[i].vin)) == keccak256(bytes(vin))) {
                return i;
            }
        }
        revert("VIN not found");
    }

    // Admin functions
    function grantAdminRole(address account) public onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) public onlyOwner {
        revokeRole(ADMIN_ROLE, account);
    }

    // Override supportsInterface due to multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}