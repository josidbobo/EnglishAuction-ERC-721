//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EnglishAuction is ERC721, IERC721Receiver{

    using Counters for Counters.Counter;
    using Counters for uint;

    //token Id counter
    Counters.Counter public tokenId;

    // events
    event received(address a, address b, uint c, bytes d);

    // constants
    uint constant auctionTime = 60;


    constructor(string memory name, string memory symbol) ERC721(name, symbol){}

    struct AuctionNFT{
        address owner;
        uint startTime;
        bool isAuction;
        uint currentHighestBid;
        address highestBidder;
    }

    modifier NoAddressZero(){
        require(msg.sender != address(0), "Address 0 can't call this function");
        _;
    }

    mapping (uint => AuctionNFT) auctionNft;

    /// @notice To mint an NFT for the auction and assign it to the owner in the struct
    function mintNFT() external {
        uint currentId = tokenId.current();
        _mint(msg.sender, currentId);
        auctionNft[currentId].owner = msg.sender; 
        tokenId.increment();
    }

    /// @param tokenId to track which NFT is being auctioned
    /// @notice To begin the auction using the NFT id.
    function auction(uint tokenId) external {
        require(auctionNft[tokenId].owner == msg.sender, "Not the owner of this NFT");
        safeTransferFrom(msg.sender, address(this), tokenId);
        auctionNft[tokenId] = AuctionNFT(msg.sender, block.timestamp, true, 1 ether, msg.sender);
    }

    /// @notice To bid for any NFT with the Id
    function bid(uint tokenId) payable public NoAddressZero{
        require(block.timestamp - auctionNft[tokenId].startTime < auctionTime, "No longer in auction");
        require(auctionNft[tokenId].isAuction, "Not in auction");
        require(msg.value > auctionNft[tokenId].currentHighestBid, "Bid is below current Highest");
        
        AuctionNFT storage nft = auctionNft[tokenId];
        if(nft.highestBidder != nft.owner){
            require(address(this).balance >= nft.currentHighestBid);
            payable(nft.highestBidder).transfer(nft.currentHighestBid);
        }
            nft.highestBidder = msg.sender;
            nft.currentHighestBid = msg.value;
    }

    /// @notice Owner can end auction after the auction time has elapsed
    /// and the NFT is transferred
    function endAuction(uint tokenId) payable public NoAddressZero{
        require(msg.sender == auctionNft[tokenId].owner, "Not the owner of this NFT");
        require(auctionNft[tokenId].isAuction, "NFT no in auction");
        require(block.timestamp - auctionNft[tokenId].startTime < auctionTime, "No longer in auction");

        AuctionNFT storage nft = auctionNft[tokenId];
        nft.isAuction = false;
        if(nft.highestBidder != nft.owner){
            require(address(this).balance >= nft.currentHighestBid);
            payable(nft.owner).transfer(nft.currentHighestBid);
            nft.owner = nft.highestBidder;
            nft.currentHighestBid = 0;
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        emit received(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    function getHighestBid(uint tokenId) public view returns(uint) {
        return auctionNft[tokenId].currentHighestBid;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

}




