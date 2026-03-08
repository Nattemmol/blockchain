// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutoChainCore.sol";

contract AutoChainMarketplace is AutoChainCore {
    struct MarketplaceListing {
        bool isListed;
        uint256 price;
        address seller;
        address buyer;
        bool isSold;
    }

    mapping(uint256 => MarketplaceListing) public listings;

    event VehicleListed(uint256 indexed tokenId, uint256 price);
    event PurchaseRequested(uint256 indexed tokenId, address indexed buyer);
    event VehicleSold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    // List vehicle for sale
    function listVehicle(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner can list");
        require(price > 0, "Price must be positive");
        require(!vehicles[tokenId].isFrozen, "Cannot list frozen vehicle");

        listings[tokenId] = MarketplaceListing(true, price, msg.sender, address(0), false);
        emit VehicleListed(tokenId, price);
    }

    // Request purchase
    function requestPurchase(uint256 tokenId) public payable {
        require(listings[tokenId].isListed, "Vehicle not listed");
        require(msg.value == listings[tokenId].price, "Incorrect payment amount");
        require(isUserVerified(msg.sender), "Buyer must be verified");

        MarketplaceListing storage listing = listings[tokenId];
        listing.buyer = msg.sender;
        emit PurchaseRequested(tokenId, msg.sender);

        // Automate transfer
        address seller = listing.seller;
        _transfer(seller, msg.sender, tokenId);
        vehicles[tokenId].currentOwner = msg.sender;
        vehicles[tokenId].ownershipHistory.push(msg.sender);
        vehicles[tokenId].transferTimestamps.push(block.timestamp);

        listing.isSold = true;
        listing.isListed = false;

        // Transfer payment to seller
        (bool success,) = payable(seller).call{value: msg.value}("");
        require(success, "Payment transfer failed");

        emit VehicleSold(tokenId, msg.sender, msg.value);
        emit OwnershipTransferred(tokenId, seller, msg.sender);
    }

    // Get listing details
    function getListing(uint256 tokenId) public view returns (
        bool isListed,
        uint256 price,
        address seller,
        address buyer,
        bool isSold
    ) {
        MarketplaceListing memory listing = listings[tokenId];
        return (listing.isListed, listing.price, listing.seller, listing.buyer, listing.isSold);
    }
}