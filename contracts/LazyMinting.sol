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

    event Mint(
        address buyer,
        uint256 indexed tokenId,
        string indexed tokenURI,
        uint256 indexed price
    );

    constructor() ERC721("MyNFT", "MNFT") {}

    mapping(bytes => bool) private signatureUsed;

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
        emit Mint(msg.sender, voucher.tokenId, voucher.tokenURI, voucher.price);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId);
    } 
}