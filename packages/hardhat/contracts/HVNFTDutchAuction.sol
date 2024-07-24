// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HVNFTDutchAuction is ERC721, ERC721Enumerable, Ownable {
	uint256 public constant COLLECTION_SIZE = 10000; // Total number of NFTs
	uint256 public constant AUCTION_START_PRICE = 1 ether; // Starting price (highest price)
	uint256 public constant AUCTION_END_PRICE = 0.1 ether; // End price (lowest price/floor price)
	uint256 public constant AUCTION_TIME = 100 days; // Auction duration. Set to 10 minutes for testing convenience
	uint256 public constant AUCTION_DROP_INTERVAL = 7 days; // After how long the price will drop once
	uint256 public constant AUCTION_DROP_PER_STEP =
		(AUCTION_START_PRICE - AUCTION_END_PRICE) /
			(AUCTION_TIME / AUCTION_DROP_INTERVAL); // Price reduction per step

	uint256 public auctionStartTime; // Auction start timestamp
	uint256 private _nextTokenId;

	error SaleNotStartedYet();
	error NotEnoughRemainingReservedNFTs();
	error NotEnoughETH();
	error TransferFailed();

	constructor(
		address initialOwner
	) ERC721("HoangVuNFT", "HVNFT") Ownable(initialOwner) {
		auctionStartTime = block.timestamp;
	}

	function auctionMint(uint256 quantity) external payable {
		uint256 _saleStartTime = uint256(auctionStartTime);
		if (_saleStartTime == 0 || block.timestamp < _saleStartTime) {
			revert SaleNotStartedYet();
		}

		if (_nextTokenId + quantity > COLLECTION_SIZE) {
			revert NotEnoughRemainingReservedNFTs();
		}

		uint256 totalCost = getAuctionPrice() * quantity;
		if (msg.value < totalCost) {
			revert NotEnoughETH();
		}

		for (uint256 i = 0; i < quantity; i++) {
			uint256 tokenId = _nextTokenId++;
			_safeMint(msg.sender, tokenId);
		}

		if (msg.value > totalCost) {
			(bool success, ) = payable(msg.sender).call{
				value: msg.value - totalCost
			}("");
			if (!success) {
				revert TransferFailed();
			}
		}
	}

	function setAuctionStartTime(uint32 timestamp) external onlyOwner {
		auctionStartTime = timestamp;
	}

	function withdrawMoney() external onlyOwner {
		(bool success, ) = msg.sender.call{ value: address(this).balance }("");
		if (!success) {
			revert TransferFailed();
		}
	}

	function getAuctionPrice() public view returns (uint256) {
		if (block.timestamp < auctionStartTime) {
			return AUCTION_START_PRICE;
		} else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
			return AUCTION_END_PRICE;
		} else {
			uint256 steps = (block.timestamp - auctionStartTime) /
				AUCTION_DROP_INTERVAL;
			return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
		}
	}

	function _baseURI() internal pure override returns (string memory) {
		return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
	}

	// The following functions are overrides required by Solidity.

	function _update(
		address to,
		uint256 tokenId,
		address auth
	) internal override(ERC721, ERC721Enumerable) returns (address) {
		return super._update(to, tokenId, auth);
	}

	function _increaseBalance(
		address account,
		uint128 value
	) internal override(ERC721, ERC721Enumerable) {
		super._increaseBalance(account, value);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
