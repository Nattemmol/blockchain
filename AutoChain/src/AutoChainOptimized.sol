// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AutoChainOptimized is ERC721, Ownable, AccessControl {
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");
    bytes32 public constant SERVICE_PROVIDER_ROLE = keccak256("SERVICE_PROVIDER_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");

    // Use bytes32 for strings to save space
    struct Vehicle {
        bytes32 vin;
        bytes32 status;
        address currentOwner;
        address[] ownershipHistory;
        uint256[] transferTimestamps;
        bool isFrozen;
        uint256 packedData; // Pack multiple bools/flags into one uint256
    }

    struct UserIdentity {
        bool isVerified;
        bytes32 name;
        bytes32 idNumber;
        uint256 verifiedAt;
    }

    struct Lien {
        address bank;
        uint256 amount;
        uint256 data; // Pack isActive (1 bit) and createdAt (255 bits)
    }

    struct MarketplaceListing {
        uint256 data; // Pack isListed (1), isSold (1), price (128), seller (80), buyer (80)
    }

    // Storage
    mapping(uint256 => Vehicle) public vehicles;
    mapping(bytes32 => uint256) public vinToTokenId;
    mapping(address => UserIdentity) public userIdentities;
    mapping(uint256 => Lien[]) public liens;
    mapping(uint256 => MarketplaceListing) public listings;
    mapping(uint256 => bytes32[]) public records; // accident/maintenance records

    uint256 public nextTokenId = 1;
    uint256 public totalVehicles;

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

        address[] memory history = new address[](1);
        history[0] = initialOwner;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        vehicles[tokenId] = Vehicle(vin, keccak256("active"), initialOwner, history, timestamps, false, 0);
        vinToTokenId[vin] = tokenId;
        totalVehicles++;

        emit VehicleRegistered(tokenId, vin, initialOwner);
    }

    function transferOwnership(uint256 tokenId, address to) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(to != address(0), "Invalid address");
        require(!vehicles[tokenId].isFrozen, "Vehicle frozen");
        require(vehicles[tokenId].status != keccak256("stolen"), "Stolen vehicle");
        require(!hasActiveLien(tokenId), "Active lien");

        address from = msg.sender;
        _transfer(from, to, tokenId);

        Vehicle storage v = vehicles[tokenId];
        v.currentOwner = to;
        v.ownershipHistory.push(to);
        v.transferTimestamps.push(block.timestamp);

        emit OwnershipTransferred(tokenId, from, to);
    }

    function updateStatus(uint256 tokenId, bytes32 newStatus) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        vehicles[tokenId].status = newStatus;
        emit StatusUpdated(tokenId, newStatus);
    }

    function verifyUser(address user, bytes32 name, bytes32 idNumber) public onlyRole(AUTHORITY_ROLE) {
        userIdentities[user] = UserIdentity(true, name, idNumber, block.timestamp);
        emit UserVerified(user, name);
    }

    function isUserVerified(address user) public view returns (bool) {
        return userIdentities[user].isVerified;
    }

    function freezeVehicle(uint256 tokenId) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        vehicles[tokenId].isFrozen = true;
        emit VehicleFrozen(tokenId);
    }

    function unfreezeVehicle(uint256 tokenId) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        vehicles[tokenId].isFrozen = false;
        emit VehicleUnfrozen(tokenId);
    }

    // Marketplace functions
    function listVehicle(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(price > 0 && price < 2**128, "Invalid price");
        require(!vehicles[tokenId].isFrozen, "Vehicle frozen");

        // Pack data: isListed (bit 255), isSold (bit 254), price (bits 126-0), seller (bits 206-127), buyer (bits 286-207)
        uint256 packed = (1 << 255); // isListed = true
        packed |= (uint256(uint160(msg.sender)) << 127); // seller
        packed |= price; // price in lower 127 bits
        listings[tokenId] = MarketplaceListing(packed);

        emit VehicleListed(tokenId, price);
    }

    function requestPurchase(uint256 tokenId) public payable {
        MarketplaceListing storage listing = listings[tokenId];
        uint256 packed = listing.data;
        bool isListed = (packed >> 255) & 1 == 1;
        bool isSold = (packed >> 254) & 1 == 1;
        require(isListed, "Not listed");
        require(!isSold, "Already sold");

        uint256 price = packed & ((1 << 127) - 1);
        require(msg.value == price, "Wrong price");
        require(isUserVerified(msg.sender), "Buyer not verified");

        address seller = address(uint160((packed >> 127) & ((1 << 80) - 1)));

        // Set isSold, clear isListed, set buyer
        packed = packed & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // Clear isListed (bit 255)
        packed = packed | (1 << 254); // Set isSold (bit 254)
        packed = packed | (uint256(uint160(msg.sender)) << 207); // Set buyer (bits 286-207)
        listing.data = packed;

        _transfer(seller, msg.sender, tokenId);
        Vehicle storage v = vehicles[tokenId];
        v.currentOwner = msg.sender;
        v.ownershipHistory.push(msg.sender);
        v.transferTimestamps.push(block.timestamp);

        (bool success,) = payable(seller).call{value: msg.value}("");
        require(success, "Payment failed");

        emit VehicleSold(tokenId, msg.sender, msg.value);
        emit OwnershipTransferred(tokenId, seller, msg.sender);
    }

    // Lien functions
    function registerLien(uint256 tokenId, uint256 amount) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        require(amount > 0, "Invalid amount");

        liens[tokenId].push(Lien(msg.sender, amount, (1 << 255) | block.timestamp));
        emit LienRegistered(tokenId, msg.sender, amount);
    }

    function clearLien(uint256 tokenId, address bank) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");

        Lien[] storage vehicleLiens = liens[tokenId];
        for (uint256 i = 0; i < vehicleLiens.length; i++) {
            if (vehicleLiens[i].bank == bank && (vehicleLiens[i].data >> 255) & 1 == 1) {
                vehicleLiens[i].data = vehicleLiens[i].data & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // Clear isActive
                emit LienCleared(tokenId, bank);
                return;
            }
        }
        revert("Active lien not found");
    }

    function hasActiveLien(uint256 tokenId) public view returns (bool) {
        Lien[] memory vehicleLiens = liens[tokenId];
        for (uint256 i = 0; i < vehicleLiens.length; i++) {
            if ((vehicleLiens[i].data >> 255) & 1 == 1) return true;
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

    // View functions
    function getVehicleDetails(uint256 tokenId) public view returns (
        bytes32 vin, bytes32 status, address currentOwner,
        address[] memory history, uint256[] memory timestamps, bool isFrozen
    ) {
        require(_ownerOf(tokenId) != address(0), "Vehicle not found");
        Vehicle memory v = vehicles[tokenId];
        return (v.vin, v.status, v.currentOwner, v.ownershipHistory, v.transferTimestamps, v.isFrozen);
    }

    function getTokenIdByVin(bytes32 vin) public view returns (uint256) {
        uint256 tokenId = vinToTokenId[vin];
        require(tokenId != 0, "VIN not found");
        return tokenId;
    }

    function getListing(uint256 tokenId) public view returns (bool isListed, bool isSold, uint256 price, address seller, address buyer) {
        uint256 packed = listings[tokenId].data;
        isListed = (packed >> 255) & 1 == 1;
        isSold = (packed >> 254) & 1 == 1;
        price = packed & ((1 << 127) - 1);
        seller = address(uint160((packed >> 127) & ((1 << 80) - 1)));
        buyer = address(uint160((packed >> 207) & ((1 << 80) - 1)));
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