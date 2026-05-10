// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutoChainCore.sol";

contract AutoChainLiens is AutoChainCore {
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");

    struct Lien {
        address bank;
        uint256 amount;
        bool isActive;
        uint256 createdAt;
    }

    mapping(uint256 => Lien[]) public liens;

    event LienRegistered(uint256 indexed tokenId, address indexed bank, uint256 amount);
    event LienCleared(uint256 indexed tokenId, address indexed bank);

    constructor() {
        _grantRole(BANK_ROLE, msg.sender);
    }

    // Register lien
    function registerLien(uint256 tokenId, uint256 amount) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");
        require(amount > 0, "Amount must be positive");

        liens[tokenId].push(Lien(msg.sender, amount, true, block.timestamp));
        emit LienRegistered(tokenId, msg.sender, amount);
    }

    // Clear lien
    function clearLien(uint256 tokenId, address bank) public onlyRole(BANK_ROLE) {
        require(_ownerOf(tokenId) != address(0), "Vehicle does not exist");

        Lien[] storage vehicleLiens = liens[tokenId];
        for (uint256 i = 0; i < vehicleLiens.length; i++) {
            if (vehicleLiens[i].bank == bank && vehicleLiens[i].isActive) {
                vehicleLiens[i].isActive = false;
                emit LienCleared(tokenId, bank);
                return;
            }
        }
        revert("Active lien not found for this bank");
    }

    // Check if vehicle has active lien
    function hasActiveLien(uint256 tokenId) public view returns (bool) {
        Lien[] memory vehicleLiens = liens[tokenId];
        for (uint256 i = 0; i < vehicleLiens.length; i++) {
            if (vehicleLiens[i].isActive) {
                return true;
            }
        }
        return false;
    }

    // Get liens for a vehicle
    function getLiens(uint256 tokenId) public view returns (Lien[] memory) {
        return liens[tokenId];
    }

    // Override transfer to check liens
    function transferOwnership(uint256 tokenId, address to) public override {
        require(!hasActiveLien(tokenId), "Cannot transfer vehicle with active lien");
        super.transferOwnership(tokenId, to);
    }

    // Grant bank role
    function grantBankRole(address account) public onlyOwner {
        grantRole(BANK_ROLE, account);
    }
}