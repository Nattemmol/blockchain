// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AutoChainRegistry
 * @author AutoChain
 * @notice Decentralized Automobile Ownership Registry (PoC)
 * @dev This contract is NOT a legal registry. It acts as a decentralized trust layer.
 */
contract AutoChainRegistry is ERC721, Ownable {

    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    enum VehicleStatus {
        Active,
        Stolen,
        Scrapped
    }

    struct Vehicle {
        string vin;                // Vehicle Identification Number
        string metadataURI;         // Off-chain metadata (IPFS / HTTPS)
        VehicleStatus status;       // Current vehicle status
        uint256 registeredAt;       // Timestamp of registration
    }

    struct OwnershipRecord {
        address owner;
        uint256 timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 private _nextTokenId;

    // tokenId => Vehicle
    mapping(uint256 => Vehicle) private vehicles;

    // VIN => tokenId (prevents duplicate registration)
    mapping(string => uint256) private vinToTokenId;

    // tokenId => ownership history
    mapping(uint256 => OwnershipRecord[]) private ownershipHistory;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event VehicleRegistered(
        uint256 indexed tokenId,
        string vin,
        address indexed owner
    );

    event VehicleTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    event VehicleStatusUpdated(
        uint256 indexed tokenId,
        VehicleStatus status
    );

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("AutoChain Vehicle NFT", "ACVN") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier vehicleExists(uint256 tokenId) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        _;
    }

    modifier onlyVehicleOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not vehicle owner");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register a new vehicle and mint ownership NFT
     * @dev Only callable by admin (contract owner)
     */
    function registerVehicle(
        string calldata vin,
        string calldata metadataURI,
        address initialOwner
    ) external onlyOwner {
        require(vinToTokenId[vin] == 0, "Vehicle already registered");
        require(initialOwner != address(0), "Invalid owner");

        _nextTokenId++;
        uint256 tokenId = _nextTokenId;

        vehicles[tokenId] = Vehicle({
            vin: vin,
            metadataURI: metadataURI,
            status: VehicleStatus.Active,
            registeredAt: block.timestamp
        });

        vinToTokenId[vin] = tokenId;

        _safeMint(initialOwner, tokenId);

        ownershipHistory[tokenId].push(
            OwnershipRecord({
                owner: initialOwner,
                timestamp: block.timestamp
            })
        );

        emit VehicleRegistered(tokenId, vin, initialOwner);
    }

    /**
     * @notice Update vehicle legal/status information
     */
    function updateVehicleStatus(
        uint256 tokenId,
        VehicleStatus status
    ) external onlyOwner vehicleExists(tokenId) {
        vehicles[tokenId].status = status;
        emit VehicleStatusUpdated(tokenId, status);
    }

    /*//////////////////////////////////////////////////////////////
                        OWNERSHIP TRANSFER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer vehicle ownership to another wallet
     * @dev Only current owner can call
     */
    function transferVehicle(
        uint256 tokenId,
        address newOwner
    ) external vehicleExists(tokenId) onlyVehicleOwner(tokenId) {
        require(newOwner != address(0), "Invalid new owner");

        address previousOwner = ownerOf(tokenId);

        _safeTransfer(previousOwner, newOwner, tokenId, "");

        ownershipHistory[tokenId].push(
            OwnershipRecord({
                owner: newOwner,
                timestamp: block.timestamp
            })
        );

        emit VehicleTransferred(tokenId, previousOwner, newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                        PUBLIC READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getVehicle(uint256 tokenId)
        external
        view
        vehicleExists(tokenId)
        returns (
            string memory vin,
            string memory metadataURI,
            VehicleStatus status,
            address currentOwner,
            uint256 registeredAt
        )
    {
        Vehicle memory v = vehicles[tokenId];
        return (
            v.vin,
            v.metadataURI,
            v.status,
            ownerOf(tokenId),
            v.registeredAt
        );
    }

    function getOwnershipHistory(uint256 tokenId)
        external
        view
        vehicleExists(tokenId)
        returns (OwnershipRecord[] memory)
    {
        return ownershipHistory[tokenId];
    }

    function getTokenIdByVIN(string calldata vin)
        external
        view
        returns (uint256)
    {
        return vinToTokenId[vin];
    }

    /*//////////////////////////////////////////////////////////////
                    OVERRIDES (SOUL OF OWNERSHIP)
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Prevent transfers except via transferVehicle()
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        if (auth != address(0) && to != address(0)) {
            // Transfers must go through transferVehicle()
            require(auth == address(this), "Direct transfer disabled");
        }
        return super._update(to, tokenId, auth);
    }
}
