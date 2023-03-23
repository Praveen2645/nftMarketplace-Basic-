//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Market {
    //its for to know the staus of listing
	enum ListingStatus {
		Active,
		Sold,
		Cancelled
	}
//structure for listing tokens
	struct Listing {
		ListingStatus status;
		address seller;
		address token;
		uint tokenId;
		uint price;
	}
//events
	event Listed(
		uint listingId,
		address seller,
		address token,
		uint tokenId,
		uint price
	);

	event Sale(
		uint listingId,
		address buyer,
		address token,
		uint tokenId,
		uint price
	);

	event Cancel(
		uint listingId,
		address seller
	);

	uint private _listingId = 0;//unique id for token

    //mapping for id to struct
	mapping(uint => Listing) private _listings;

//function for listing the tokens in the market
	function listToken(address token, uint tokenId, uint price) external {
		IERC721(token).transferFrom(msg.sender, address(this), tokenId);// transfering listed tokens to the contract address

		Listing memory listing = Listing(
			ListingStatus.Active,
			msg.sender,
			token,
			tokenId,
			price
		);

		_listingId++;

		_listings[_listingId] = listing;

		emit Listed(
			_listingId,
			msg.sender,
			token,
			tokenId,
			price
		);
	}
//function to return the struct
	function getListing(uint listingId) public view returns (Listing memory) {
		return _listings[listingId];
	}

//function to buy the listed tokens
	function buyToken(uint listingId) external payable {
		Listing storage listing = _listings[listingId];

		require(msg.sender != listing.seller, "Seller cannot be buyer");
		require(listing.status == ListingStatus.Active, "Listing is not active");

		require(msg.value >= listing.price, "Insufficient payment");

		listing.status = ListingStatus.Sold;

		IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId); // token transfering (from address,to address,id) 
		payable(listing.seller).transfer(listing.price);// paying the seller for the token 

		emit Sale(
			listingId,
			msg.sender,
			listing.token,
			listing.tokenId,
			listing.price
		);
	}
//function to cancel the  token listing
	function cancel(uint listingId) public {
		Listing storage listing = _listings[listingId];

		require(msg.sender == listing.seller, "Only seller can cancel listing");
		require(listing.status == ListingStatus.Active, "Listing is not active");

		listing.status = ListingStatus.Cancelled;
	
		IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);

		emit Cancel(listingId, listing.seller);
	}
}
