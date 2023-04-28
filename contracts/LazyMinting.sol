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

    struct SaleNFTVoucher {
        uint256 tokenId;
        uint256 price;
        string tokenURI; 
    }

    struct AuctionNFTVoucher {
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
    mapping(uint256 => AuctionNFTVoucher) private auctionNFTVoucher;
    mapping(address => mapping(uint256 => bool)) private isBidded;

    function buyNFT(SaleNFTVoucher calldata voucher, bytes32 hash, bytes memory signature) nonReentrant external payable {
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        require(!signatureUsed[signature], "Already signature used");
        signer = recoverSigner(hash, signature);
        require(signer != msg.sender,"You cannot buy your own NFT");
        require(msg.value == voucher.price, "Invalid price");
        // assign token to the signer, and transfer it to on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.tokenURI);
        _transfer(signer, msg.sender, voucher.tokenId);
        payable(signer).transfer(voucher.price);
        signatureUsed[signature] = true;
        emit Mint(voucher.tokenId, voucher.tokenURI, voucher.price);
    }

    function bidNFT(uint256 _tokenId, uint256 _startTime, uint256 _endTime, string memory _tokenURI, bytes32 hash, bytes memory signature) nonReentrant external payable {
        require(msg.value > 0 && _startTime > 0 && _endTime > 0, "Invalid parameters");
        require(bytes(_tokenURI).length > 0, "Invalid TokenURI");  
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        require(!signatureUsed[signature], "Already signature used");
        require(block.timestamp >= _startTime, "Auction not started yet");
        require(msg.value >= auctionNFTVoucher[_tokenId].basePrice, "Invalid basePrice");
        require(block.timestamp <= _endTime, "Auction time ended");
        require(!auctionNFTVoucher[_tokenId].isAuctionEnded, "Auction ended");
        require(signer != msg.sender,"You cannot bid on your own NFT");
        uint256 previousHighestBid = auctionNFTVoucher[_tokenId].highestBid;
        require(msg.value > previousHighestBid, "Invalid previousHighestBid");
        signer = recoverSigner(hash, signature);
        address previousHighestBidder = auctionNFTVoucher[_tokenId].highestBidder;
        auctionNFTVoucher[_tokenId].startTime = _startTime;
        auctionNFTVoucher[_tokenId].endTime = _endTime;
        auctionNFTVoucher[_tokenId].tokenURI = _tokenURI;
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
            auctionNFTVoucher[_tokenId].highestBidder = msg.sender;
            auctionNFTVoucher[_tokenId].highestBid = msg.value;
            auctionNFTVoucher[_tokenId].tokenId = _tokenId;
            emit NftBidded(_tokenId, msg.sender, msg.value, block.timestamp, auctionNFTVoucher[_tokenId].endTime);
        }
    }

    function claimNFT(uint256 _tokenId, bytes32 hash, bytes memory signature) nonReentrant external {
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        require(!signatureUsed[signature], "Already signature used");
        require(block.timestamp >= auctionNFTVoucher[_tokenId].startTime, "Auction not started yet");
        require(block.timestamp >= auctionNFTVoucher[_tokenId].endTime, "Auction time not yet ended");
        require(auctionNFTVoucher[_tokenId].highestBidder == msg.sender, "You are not highest bidder");
        require(!auctionNFTVoucher[_tokenId].isAuctionEnded, "Auction already ended");
        require(auctionNFTVoucher[_tokenId].highestBid != 0, "Highest bid canot be 0");
        signer = recoverSigner(hash, signature);
        // assign token to the signer, and transfer it to on-chain
        _mint(signer, auctionNFTVoucher[_tokenId].tokenId);
        _setTokenURI(auctionNFTVoucher[_tokenId].tokenId, auctionNFTVoucher[_tokenId].tokenURI);
        _transfer(signer, auctionNFTVoucher[_tokenId].highestBidder, auctionNFTVoucher[_tokenId].tokenId);
        payable(signer).transfer(auctionNFTVoucher[_tokenId].highestBid);
        auctionNFTVoucher[_tokenId].isAuctionEnded = true;
        signatureUsed[signature] = true;
        auctionNFTVoucher[_tokenId].basePrice = 0;
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function getAuctionInfo(uint256 _tokenId) external view returns (AuctionNFTVoucher memory) {
        return auctionNFTVoucher[_tokenId];
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