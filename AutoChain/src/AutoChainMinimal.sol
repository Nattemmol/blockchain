// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AutoChainMinimal is ERC721, Ownable, AccessControl {
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");
    bytes32 public constant SERVICE_PROVIDER_ROLE = keccak256("SERVICE_PROVIDER_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");

    struct Vehicle {
        bytes32 vin;
        bytes32 status;
        address currentOwner;
        uint256 packedData; // isFrozen (1 bit), ownership count (32 bits), lien count (32 bits)
    }

    struct UserIdentity {
        bool isVerified;
        bytes32 name;
        uint256 verifiedAt;
    }

    // Storage
    mapping(uint256 => Vehicle) public vehicles;
    mapping(bytes32 => uint256) public vinToTokenId;
    mapping(address => UserIdentity) public userIdentities;
    mapping(uint256 => address[]) public ownershipHistory;
    mapping(uint256 => uint256[]) public transferTimestamps;
    mapping(uint256 => bytes32[]) public records; // accident/maintenance records
    mapping(uint256 => uint256[]) public liens; // packed: bank (160 bits), amount (64 bits), isActive (1 bit), timestamp (32 bits)

    uint256 public nextTokenId = 1;

    // Events
    event VehicleRegistered(uint256 indexed tokenId, bytes32 vin, address indexed owner);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event StatusUpdated(uint256 indexed tokenId, bytes32 newStatus);
    event UserVerified(address indexed user, bytes32 name);
    event VehicleFrozen(uint256 indexed tokenId);
    event VehicleUnfrozen(uint256 indexed tokenId);
    event LienRegistered(uint256 indexed tokenId, address indexed bank, uint256 amount);
    event LienCleared(uint256 indexed tokenId, address indexed bank);
    event VehicleListed(uint256 indexed tokenId, uint256 price);
    event VehicleSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event RecordAdded(uint256 indexed tokenId, bytes32 recordType, bytes32 description);

    constructor() ERC721("AutoChain Vehicle", "AUTO") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AUTHORITY_ROLE, msg.sender);
        _grantRole(SERVICE_PROVIDER_ROLE, msg.sender);
        _grantRole(BANK_ROLE, msg.sender);
    }

    // Core functions
    function registerVehicle(bytes32 vin, address initialOwner) public onlyRole(AUTHORITY_ROLE) {
        require(vin != bytes32(0), "VIN required");
        require(vinToTokenId[vin] == 0, "VIN exists");
        require(isUserVerified(initialOwner), "Owner not verified");

        uint256 tokenId = nextTokenId++;
        _mint(initialOwner, tokenId);

        vehicles[tokenId] = Vehicle(vin, keccak256("active"), initialOwner, 0);
        vinToTokenId[vin] = tokenId;

        ownershipHistory[tokenId].push(initialOwner);
        transferTimestamps[tokenId].push(block.timestamp);

        emit VehicleRegistered(tokenId, vin, initialOwner);
    }

    function transferOwnership(uint256 tokenId, address to) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(to != address(0), "Invalid address");
        require(!isFrozen(tokenId), "Vehicle frozen");
        require(getStatus(tokenId) != keccak256("stolen"), "Stolen vehicle");
        require(!hasActiveLien(tokenId), "Active lien");

        address from = msg.sender;
        _transfer(from, to, tokenId);

        vehicles[tokenId].currentOwner = to;
        ownershipHistory[tokenId].push(to);
        transferTimestamps[tokenId].push(block.timestamp);

        emit OwnershipTransferred(tokenId, from, to);
    }

    function updateStatus(uint256 tokenId, bytes32 newStatus) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        vehicles[tokenId].status = newStatus;
        emit StatusUpdated(tokenId, newStatus);
    }

    function verifyUser(address user, bytes32 name) public onlyRole(AUTHORITY_ROLE) {
        userIdentities[user] = UserIdentity(true, name, block.timestamp);
        emit UserVerified(user, name);
    }

    function isUserVerified(address user) public view returns (bool) {
        return userIdentities[user].isVerified;
    }

    function freezeVehicle(uint256 tokenId) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        vehicles[tokenId].packedData |= (1 << 255); // Set frozen bit
        emit VehicleFrozen(tokenId);
    }

    function unfreezeVehicle(uint256 tokenId) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        vehicles[tokenId].packedData &= ~(uint256(1) << 255); // Clear frozen bit
        emit VehicleUnfrozen(tokenId);
    }

    // Lien functions
    function registerLien(uint256 tokenId, uint256 amount) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        require(amount > 0 && amount < (1 << 64), "Invalid amount");

        uint256 packedLien = uint256(uint160(msg.sender)) | (amount << 160) | (uint256(1) << 224) | (block.timestamp << 225);
        liens[tokenId].push(packedLien);
        emit LienRegistered(tokenId, msg.sender, amount);
    }

    function clearLien(uint256 tokenId, address bank) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");

        uint256[] storage vehicleLiens = liens[tokenId];
        for (uint256 i = 0; i < vehicleLiens.length; i++) {
            uint256 packed = vehicleLiens[i];
            address lienBank = address(uint160(packed & ((1 << 160) - 1)));
            bool isActive = (packed >> 224) & 1 == 1;

            if (lienBank == bank && isActive) {
                vehicleLiens[i] = packed & ~(uint256(1) << 224); // Clear isActive
                emit LienCleared(tokenId, bank);
                return;
            }
        }
        revert("Active lien not found");
    }

    function hasActiveLien(uint256 tokenId) public view returns (bool) {
        uint256[] memory vehicleLiens = liens[tokenId];
        for (uint256 i = 0; i < vehicleLiens.length; i++) {
            if ((vehicleLiens[i] >> 224) & 1 == 1) return true;
        }
        return false;
    }

    // Records functions
    function addRecord(uint256 tokenId, bytes32 recordType, bytes32 description) public onlyRole(SERVICE_PROVIDER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        require(description != bytes32(0), "Empty description");

        records[tokenId].push(recordType);
        records[tokenId].push(description);

        emit RecordAdded(tokenId, recordType, description);
    }

    // Helper functions
    function isFrozen(uint256 tokenId) public view returns (bool) {
        return (vehicles[tokenId].packedData >> 255) & 1 == 1;
    }

    function getStatus(uint256 tokenId) public view returns (bytes32) {
        return vehicles[tokenId].status;
    }

    function getVehicleDetails(uint256 tokenId) public view returns (
        bytes32 vin, bytes32 status, address currentOwner, bool frozen
    ) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        Vehicle memory v = vehicles[tokenId];
        return (v.vin, v.status, v.currentOwner, isFrozen(tokenId));
    }

    function getTokenIdByVin(bytes32 vin) public view returns (uint256) {
        uint256 tokenId = vinToTokenId[vin];
        require(tokenId != 0, "VIN not found");
        return tokenId;
    }

    function getOwnershipHistory(uint256 tokenId) public view returns (address[] memory owners, uint256[] memory timestamps) {
        return (ownershipHistory[tokenId], transferTimestamps[tokenId]);
    }

    function getRecords(uint256 tokenId) public view returns (bytes32[] memory) {
        return records[tokenId];
    }

    // Admin functions
    function grantAuthorityRole(address account) public onlyOwner {
        grantRole(AUTHORITY_ROLE, account);
    }

    function grantServiceProviderRole(address account) public onlyOwner {
        grantRole(SERVICE_PROVIDER_ROLE, account);
    }

    function grantBankRole(address account) public onlyOwner {
        grantRole(BANK_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}