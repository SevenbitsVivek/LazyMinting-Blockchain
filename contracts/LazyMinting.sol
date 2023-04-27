// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract LazyMinting is  ERC721URIStorage, Ownable, ReentrancyGuard{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    using ECDSA for bytes32;

    // Create a new role identifier for the minter role
    address signer;

    struct NFTVoucher {
        uint256 tokenId;
        uint256 price;
        string tokenURI; 
    }

    struct AuctionNFT {
        uint256 tokenId;
        uint256 basePrice;
        string tokenURI; 
        bool isAuctionEnded;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
    }

    event Mint(
        uint256 indexed tokenId,
        string indexed tokenURI,
        uint256 indexed price
    );

    constructor() ERC721("MyNFT", "MNFT") {}

    event NftBidded(uint256 indexed _tokenId, address _bidder, uint256 indexed _bidAmount, uint256 _startTime, uint256 _endTime);

    mapping(bytes => bool) private signatureUsed;
    mapping(uint256 => AuctionNFT) private auctionNft;
    mapping(address => mapping(uint256 => bool)) private isBidded;

    function redeem(NFTVoucher calldata voucher, bytes32 hash, bytes memory signature) nonReentrant external payable {
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        signer = recoverSigner(hash, signature);
        require(!signatureUsed[signature], "Already signature used");
        require(signer != msg.sender,"You cannot buy your own NFT");
        require(msg.value == voucher.price, "Insufficient Funds!!");
        // assign token to the signer, and transfer it to on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.tokenURI);
        _transfer(signer, msg.sender, voucher.tokenId);
        payable(signer).transfer(voucher.price);
        signatureUsed[signature] = true;
        emit Mint(voucher.tokenId, voucher.tokenURI, voucher.price);
    }

    function bidNFT(uint256 _tokenId, uint256 _startTime, uint256 _endTime, bytes32 hash, bytes memory signature) nonReentrant external payable {
        require(msg.value > 0, "Value cannot be 0");
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        signer = recoverSigner(hash, signature);
        require(block.timestamp >= _startTime, "Auction not started yet");
        require(msg.value >= auctionNft[_tokenId].basePrice, "Invalid basePrice");
        require(block.timestamp <= _endTime, "Auction time ended");
        require(!auctionNft[_tokenId].isAuctionEnded, "Auction ended");
        require(!signatureUsed[signature], "Already signature used");
        require(signer != msg.sender,"You cannot bid on your own NFT");
        uint256 previousHighestBid = auctionNft[_tokenId].highestBid;
        require(msg.value > previousHighestBid, "Invalid previousHighestBid");
        address previousHighestBidder = auctionNft[_tokenId].highestBidder;
        auctionNft[_tokenId].startTime = _startTime;
        auctionNft[_tokenId].endTime = _endTime;
        if (msg.value > previousHighestBid) {
            if(!isBidded[msg.sender][_tokenId]) {
                isBidded[msg.sender][_tokenId] = true;
            }
            // Refund previous highest bidder
            if (previousHighestBidder != address(0) && previousHighestBid != 0) {
                require(address(this).balance >= previousHighestBid, "Not enough balance");
                payable(previousHighestBidder).transfer(previousHighestBid);
            }
            // Update auction information with new highest bidder and bid
            auctionNft[_tokenId].highestBidder = msg.sender;
            auctionNft[_tokenId].highestBid = msg.value;
            auctionNft[_tokenId].tokenId = _tokenId;
            emit NftBidded(_tokenId, msg.sender, msg.value, block.timestamp, auctionNft[_tokenId].endTime);
        }
    }

    function endAuction(uint256 _tokenId, bytes32 hash, bytes memory signature) nonReentrant external {
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        signer = recoverSigner(hash, signature);
        require(msg.sender == owner(), "Invalid nft owner");
        require(block.timestamp >= auctionNft[_tokenId].startTime, "Auction not started yet");
        require(block.timestamp >= auctionNft[_tokenId].endTime, "Auction time not yet ended");
        require(!auctionNft[_tokenId].isAuctionEnded, "Auction already ended");
        require(auctionNft[_tokenId].highestBid != 0, "Highest bid canot be 0");
        // assign token to the signer, and transfer it to on-chain
        _mint(msg.sender, auctionNft[_tokenId].tokenId);
        _setTokenURI(auctionNft[_tokenId].tokenId, auctionNft[_tokenId].tokenURI);
        _transfer(msg.sender, auctionNft[_tokenId].highestBidder, auctionNft[_tokenId].tokenId);
        payable(msg.sender).transfer(auctionNft[_tokenId].highestBid);
        auctionNft[_tokenId].isAuctionEnded = true;
        signatureUsed[signature] = true;
        auctionNft[_tokenId].basePrice = 0;
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function getAuctionInfo(uint256 _tokenId) external view returns (AuctionNFT memory) {
        return auctionNft[_tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId);
    } 
}