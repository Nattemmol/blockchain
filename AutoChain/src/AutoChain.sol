// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AutoChain is ERC721, Ownable, AccessControl {
    using Strings for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");
    bytes32 public constant SERVICE_PROVIDER_ROLE = keccak256("SERVICE_PROVIDER_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");

    struct Vehicle {
        string vin;
        string status; // e.g., "active", "stolen", "scrapped"
        address[] ownershipHistory;
        uint256[] transferTimestamps;
        bool isFrozen;
        string[] accidentReports;
        string[] maintenanceRecords;
        Lien[] liens;
        MarketplaceListing listing;
    }

    struct Lien {
        address bank;
        uint256 amount;
        bool isActive;
        uint256 createdAt;
    }

    struct MarketplaceListing {
        bool isListed;
        uint256 price;
        address seller;
        address buyer;
        bool isSold;
    }

    struct UserIdentity {
        bool isVerified;
        string name;
        string idNumber;
        uint256 verifiedAt;
    }

    mapping(uint256 => Vehicle) public vehicles;
    mapping(string => bool) public vinExists;
    mapping(address => UserIdentity) public userIdentities;
    mapping(uint256 => string) public vehicleCertificates; // tokenId => certificate URL or data
    uint256 public nextTokenId = 1;

    event VehicleRegistered(uint256 indexed tokenId, string vin, address indexed owner);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event StatusUpdated(uint256 indexed tokenId, string newStatus);
    event UserVerified(address indexed user, string name);
    event VehicleFrozen(uint256 indexed tokenId);
    event VehicleUnfrozen(uint256 indexed tokenId);
    event AccidentReported(uint256 indexed tokenId, string report);
    event MaintenanceRecorded(uint256 indexed tokenId, string record);
    event LienRegistered(uint256 indexed tokenId, address indexed bank, uint256 amount);
    event LienCleared(uint256 indexed tokenId, address indexed bank);
    event VehicleListed(uint256 indexed tokenId, uint256 price);
    event PurchaseRequested(uint256 indexed tokenId, address indexed buyer);
    event VehicleSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event CertificateGenerated(uint256 indexed tokenId, string certificate);

    constructor() ERC721("AutoChain Vehicle", "AUTO") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(AUTHORITY_ROLE, msg.sender);
    }

    // FR-24-26: Government/Authority Role - Updated registration
    function registerVehicle(string memory vin, address initialOwner) public onlyRole(AUTHORITY_ROLE) {
        require(bytes(vin).length > 0, "VIN is required");
        require(!vinExists[vin], "Vehicle with this VIN already exists");
        require(isUserVerified(initialOwner), "Owner must be verified");

        uint256 tokenId = nextTokenId++;
        _mint(initialOwner, tokenId);

        vehicles[tokenId] = Vehicle({
            vin: vin,
            status: "active",
            ownershipHistory: new address[](0),
            transferTimestamps: new uint256[](0),
            isFrozen: false,
            accidentReports: new string[](0),
            maintenanceRecords: new string[](0),
            liens: new Lien[](0),
            listing: MarketplaceListing(false, 0, address(0), address(0), false)
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
        require(!vehicles[tokenId].isFrozen, "Vehicle is frozen");
        require(keccak256(bytes(vehicles[tokenId].status)) != keccak256(bytes("stolen")), "Cannot transfer stolen vehicle");
        require(!hasActiveLien(tokenId), "Cannot transfer vehicle with active lien");

        address from = msg.sender;
        _transfer(from, to, tokenId);

        vehicles[tokenId].ownershipHistory.push(to);
        vehicles[tokenId].transferTimestamps.push(block.timestamp);

        emit OwnershipTransferred(tokenId, from, to);
    }

    // FR-16: Authorized users can update status
    function updateStatus(uint256 tokenId, string memory newStatus) public onlyRole(AUTHORITY_ROLE) {
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
        uint256[] memory timestamps,
        bool isFrozen,
        string[] memory accidents,
        string[] memory maintenance,
        Lien[] memory liens,
        MarketplaceListing memory listing
    ) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        Vehicle memory v = vehicles[tokenId];
        return (v.vin, v.status, ownerOf(tokenId), v.ownershipHistory, v.transferTimestamps, v.isFrozen, v.accidentReports, v.maintenanceRecords, v.liens, v.listing);
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

    // FR-21-23: Identity & Authorization System
    function verifyUser(address user, string memory name, string memory idNumber) public onlyRole(AUTHORITY_ROLE) {
        userIdentities[user] = UserIdentity(true, name, idNumber, block.timestamp);
        emit UserVerified(user, name);
    }

    function isUserVerified(address user) public view returns (bool) {
        return userIdentities[user].isVerified;
    }

    function freezeVehicle(uint256 tokenId) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        vehicles[tokenId].isFrozen = true;
        emit VehicleFrozen(tokenId);
    }

    function unfreezeVehicle(uint256 tokenId) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        vehicles[tokenId].isFrozen = false;
        emit VehicleUnfrozen(tokenId);
    }

    // FR-30-32: Accident & Damage History
    function reportAccident(uint256 tokenId, string memory report) public onlyRole(SERVICE_PROVIDER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        require(bytes(report).length > 0, "Report cannot be empty");

        vehicles[tokenId].accidentReports.push(report);
        emit AccidentReported(tokenId, report);
    }

    // FR-33-35: Service & Maintenance History
    function recordMaintenance(uint256 tokenId, string memory record) public onlyRole(SERVICE_PROVIDER_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        require(bytes(record).length > 0, "Record cannot be empty");

        vehicles[tokenId].maintenanceRecords.push(record);
        emit MaintenanceRecorded(tokenId, record);
    }

    // FR-36-38: Loan/Lien Tracking
    function registerLien(uint256 tokenId, uint256 amount) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        require(amount > 0, "Amount must be positive");

        vehicles[tokenId].liens.push(Lien(msg.sender, amount, true, block.timestamp));
        emit LienRegistered(tokenId, msg.sender, amount);
    }

    function clearLien(uint256 tokenId, address bank) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");

        for (uint256 i = 0; i < vehicles[tokenId].liens.length; i++) {
            if (vehicles[tokenId].liens[i].bank == bank && vehicles[tokenId].liens[i].isActive) {
                vehicles[tokenId].liens[i].isActive = false;
                emit LienCleared(tokenId, bank);
                return;
            }
        }
        revert("Active lien not found for this bank");
    }

    function hasActiveLien(uint256 tokenId) public view returns (bool) {
        for (uint256 i = 0; i < vehicles[tokenId].liens.length; i++) {
            if (vehicles[tokenId].liens[i].isActive) {
                return true;
            }
        }
        return false;
    }

    // FR-39-41: Stolen Vehicle Registry
    function markAsStolen(uint256 tokenId) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        vehicles[tokenId].status = "stolen";
        vehicles[tokenId].isFrozen = true;
        emit StatusUpdated(tokenId, "stolen");
        emit VehicleFrozen(tokenId);
    }

    // FR-42-44: Vehicle Marketplace Integration
    function listVehicle(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner can list");
        require(price > 0, "Price must be positive");
        require(!vehicles[tokenId].isFrozen, "Cannot list frozen vehicle");

        vehicles[tokenId].listing = MarketplaceListing(true, price, msg.sender, address(0), false);
        emit VehicleListed(tokenId, price);
    }

    function requestPurchase(uint256 tokenId) public payable {
        require(vehicles[tokenId].listing.isListed, "Vehicle not listed");
        require(msg.value == vehicles[tokenId].listing.price, "Incorrect payment amount");
        require(isUserVerified(msg.sender), "Buyer must be verified");

        vehicles[tokenId].listing.buyer = msg.sender;
        emit PurchaseRequested(tokenId, msg.sender);

        // Automate transfer
        address seller = vehicles[tokenId].listing.seller;
        _transfer(seller, msg.sender, tokenId);
        vehicles[tokenId].ownershipHistory.push(msg.sender);
        vehicles[tokenId].transferTimestamps.push(block.timestamp);
        vehicles[tokenId].listing.isSold = true;
        vehicles[tokenId].listing.isListed = false;

        // Transfer payment to seller
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Payment transfer failed");

        emit VehicleSold(tokenId, msg.sender, msg.value);
        emit OwnershipTransferred(tokenId, seller, msg.sender);
    }

    // FR-45-47: Digital Vehicle Certificate
    function generateCertificate(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender || hasRole(AUTHORITY_ROLE, msg.sender), "Not authorized");
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");

        // Generate a simple certificate string (in real implementation, this would be more complex)
        string memory certificate = string(abi.encodePacked(
            "Vehicle Certificate\n",
            "Token ID: ", tokenId.toString(), "\n",
            "VIN: ", vehicles[tokenId].vin, "\n",
            "Owner: ", Strings.toHexString(uint256(uint160(ownerOf(tokenId))), 20), "\n",
            "Status: ", vehicles[tokenId].status, "\n",
            "Generated at: ", block.timestamp.toString()
        ));

        vehicleCertificates[tokenId] = certificate;
        emit CertificateGenerated(tokenId, certificate);
    }

    function getCertificate(uint256 tokenId) public view returns (string memory) {
        require(bytes(vehicleCertificates[tokenId]).length > 0, "Certificate not generated");
        return vehicleCertificates[tokenId];
    }

    // Admin functions
    function grantAdminRole(address account) public onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) public onlyOwner {
        revokeRole(ADMIN_ROLE, account);
    }

    function grantAuthorityRole(address account) public onlyOwner {
        grantRole(AUTHORITY_ROLE, account);
    }

    function grantServiceProviderRole(address account) public onlyOwner {
        grantRole(SERVICE_PROVIDER_ROLE, account);
    }

    function grantBankRole(address account) public onlyOwner {
        grantRole(BANK_ROLE, account);
    }

    // Override supportsInterface due to multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}