// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AutoChainCore is ERC721, Ownable, AccessControl {
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");

    struct Vehicle {
        bytes32 vin; // Use bytes32 for efficiency
        bytes32 status; // Use bytes32 for efficiency
        address currentOwner;
        address[] ownershipHistory;
        uint256[] transferTimestamps;
        bool isFrozen;
    }

    struct UserIdentity {
        bool isVerified;
        bytes32 name; // Use bytes32 for efficiency
        bytes32 idNumber; // Use bytes32 for efficiency
        uint256 verifiedAt;
    }

    mapping(uint256 => Vehicle) public vehicles;
    mapping(bytes32 => bool) public vinExists;
    mapping(bytes32 => uint256) public vinToTokenId; // Efficient lookup
    mapping(address => UserIdentity) public userIdentities;
    uint256 public nextTokenId = 1;

    event VehicleRegistered(uint256 indexed tokenId, bytes32 vin, address indexed owner);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event StatusUpdated(uint256 indexed tokenId, bytes32 newStatus);
    event UserVerified(address indexed user, bytes32 name);
    event VehicleFrozen(uint256 indexed tokenId);
    event VehicleUnfrozen(uint256 indexed tokenId);

    constructor() ERC721("AutoChain Vehicle", "AUTO") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AUTHORITY_ROLE, msg.sender);
    }

    // Core registration function
    function registerVehicle(bytes32 vin, address initialOwner) public onlyRole(AUTHORITY_ROLE) {
        require(vin != bytes32(0), "VIN is required");
        require(!vinExists[vin], "Vehicle with this VIN already exists");
        require(isUserVerified(initialOwner), "Owner must be verified");

        uint256 tokenId = nextTokenId++;
        _mint(initialOwner, tokenId);

        address[] memory history = new address[](1);
        history[0] = initialOwner;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        vehicles[tokenId] = Vehicle({
            vin: vin,
            status: keccak256("active"),
            currentOwner: initialOwner,
            ownershipHistory: history,
            transferTimestamps: timestamps,
            isFrozen: false
        });

        vinExists[vin] = true;
        vinToTokenId[vin] = tokenId;

        emit VehicleRegistered(tokenId, vin, initialOwner);
    }

    // Transfer ownership
    function transferOwnership(uint256 tokenId, address to) public virtual {
        require(ownerOf(tokenId) == msg.sender, "Only current owner can transfer");
        require(to != address(0), "Cannot transfer to zero address");
        require(!vehicles[tokenId].isFrozen, "Vehicle is frozen");
        require(vehicles[tokenId].status != keccak256("stolen"), "Cannot transfer stolen vehicle");

        address from = msg.sender;
        _transfer(from, to, tokenId);

        vehicles[tokenId].currentOwner = to;
        vehicles[tokenId].ownershipHistory.push(to);
        vehicles[tokenId].transferTimestamps.push(block.timestamp);

        emit OwnershipTransferred(tokenId, from, to);
    }

    // Update status
    function updateStatus(uint256 tokenId, bytes32 newStatus) public onlyRole(AUTHORITY_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        vehicles[tokenId].status = newStatus;
        emit StatusUpdated(tokenId, newStatus);
    }

    // Get vehicle details
    function getVehicleDetails(uint256 tokenId) public view returns (
        bytes32 vin,
        bytes32 status,
        address currentOwner,
        address[] memory history,
        uint256[] memory timestamps,
        bool isFrozen
    ) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        Vehicle memory v = vehicles[tokenId];
        return (v.vin, v.status, v.currentOwner, v.ownershipHistory, v.transferTimestamps, v.isFrozen);
    }

    // Get token ID by VIN
    function getTokenIdByVin(bytes32 vin) public view returns (uint256) {
        require(vinExists[vin], "VIN not found");
        return vinToTokenId[vin];
    }

    // User verification
    function verifyUser(address user, bytes32 name, bytes32 idNumber) public onlyRole(AUTHORITY_ROLE) {
        userIdentities[user] = UserIdentity(true, name, idNumber, block.timestamp);
        emit UserVerified(user, name);
    }

    function isUserVerified(address user) public view returns (bool) {
        return userIdentities[user].isVerified;
    }

    // Freeze/unfreeze
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

    // Admin functions
    function grantAuthorityRole(address account) public onlyOwner {
        grantRole(AUTHORITY_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}