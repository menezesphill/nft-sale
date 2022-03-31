// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Withdrawable.sol";

contract GenNFT is
  ERC721,
  ERC721Enumerable,
  Pausable,
  Withdrawable
{
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdCounter;

  struct Whitelist {
    address account;
    uint256 allocation;
    uint256 price;
  }

  string private _hiddenBaseURI;
  string private _hiddenExtension;
  string private _revealBaseURI;
  string private _revealExtension;
  bool private _revealed;

  uint256 private _maxSupply;
  uint256 private _price;
  uint256 private _maxMintAmount;

  uint256 private _whitelistSaleTime;
  uint256 private _publicSaleTime;

  bool private _transfersPaused;

  mapping(address => uint256) private _whitelist;

  constructor(
    uint256 maxSupply_,
    uint256 price_,
    uint256 maxMintAmount_,
    uint256 whitelistSaleTime_,
    uint256 publicSaleTime_,
    string memory hiddenBaseURI_,
    string memory hiddenExtension_,
    string memory revealBaseURI_,
    string memory revealExtension_,
    bool revealed_,
    bool transfersPaused_
  )
    ERC721("GenNFT", "gNFT")
  {
    _maxSupply = maxSupply_;
    _price = price_;
    _maxMintAmount = maxMintAmount_;
    _whitelistSaleTime = whitelistSaleTime_;
    _publicSaleTime = publicSaleTime_;
    _hiddenBaseURI = hiddenBaseURI_;
    _hiddenExtension = hiddenExtension_;
    _revealBaseURI = revealBaseURI_;
    _revealExtension = revealExtension_;
    _revealed = revealed_;
    _transfersPaused = transfersPaused_;

    _tokenIdCounter.increment();
  }

  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  function price() public view returns (uint256) {
    return _price;
  }

  function maxMintAmount() public view returns (uint256) {
    return _maxMintAmount;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(uint256 amount) external payable whenNotPaused {
    require(amount >= 0, 'GenNFT: token amount is zero');
    require(
      balanceOf(msg.sender) + amount <= _maxMintAmount,
      "GenNFT: exceeds max mint limit"
    );
    require(_price * amount == msg.value, "GenNFT: Invalid eth amount");
    require(
      totalSupply() + amount <= _maxSupply,
      "GenNFT: exceeds max supply"
    );
    if (block.timestamp < _publicSaleTime) {
      revert("GenNFT: public sale hasn't started");
    }

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender);
    }
  }

  function mintWhitelist(
    uint256 amount,
    Whitelist calldata whitelist
  )
    external
    payable
    whenNotPaused
  {
    require(
      msg.sender == whitelist.account,
      "GenNFT: sender not whitelisted"
    );
    require(amount >= 0, "GenNFT: token amount is zero");
    require(
      _whitelist[msg.sender] + amount <= whitelist.allocation,
      "GenNFT: exceeds max mint limit"
    );
    require(
      whitelist.price * amount == msg.value,
      "GenNFT: invalid eth amount"
    );
    require(
      totalSupply() + amount <= _maxSupply,
      "GenNFT: exceeds max supply"
    );
    if (block.timestamp < _whitelistSaleTime) {
      revert("GenNFT: whitelist sale hasn't started");
    }

    _whitelist[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender);
    }
  }

  function mintOwner(address to, uint256 amount) external onlyOwner {
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to);
    }
  }

  function _safeMint(address to) internal {
    uint256 tokenId = _tokenIdCounter.current();
    require(tokenId <= _maxSupply, 'GenNFT: exceeds max supply');

    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (_revealed) {
      return
        string(
          abi.encodePacked(_revealBaseURI, tokenId.toString(), _revealExtension)
        );
    } else {
      return
        string(
          abi.encodePacked(_hiddenBaseURI, tokenId.toString(), _hiddenExtension)
        );
    }
  }

  function transfersPaused() public view returns (bool) {
    return _transfersPaused;
  }

  function setTransfersPaused(bool transfersPaused_) external onlyOwner {
    _transfersPaused = transfersPaused_;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    require(
      !_transfersPaused || from == address(0),
      'GenNFT: transfers are paused'
    );

    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return
      ERC721.supportsInterface(interfaceId) ||
      ERC721Enumerable.supportsInterface(interfaceId);
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    _maxSupply = maxSupply_;
  }

  function setPrice(uint256 price_) external onlyOwner {
    _price = price_;
  }

  function setMaxMintAmount(uint256 maxMintAmount_) external onlyOwner {
    _maxMintAmount = maxMintAmount_;
  }

  function setHiddenURI(string memory baseURI, string memory extension)
    external
    onlyOwner
  {
    _hiddenBaseURI = baseURI;
    _hiddenExtension = extension;
  }

  function reveal(string memory baseURI, string memory extension)
    external
    onlyOwner
  {
    _revealBaseURI = baseURI;
    _revealExtension = extension;
    _revealed = true;
  }

  function hide() external onlyOwner {
    _revealBaseURI = '';
    _revealExtension = '';
    _revealed = false;
  }

  function whitelistSaleTime() public view returns (uint256) {
    return _whitelistSaleTime;
  }

  function setWhitelistSaleTime(uint256 whitelistSaleTime_) external onlyOwner {
    _whitelistSaleTime = whitelistSaleTime_;
  }

  function publicSaleTime() public view returns (uint256) {
    return _publicSaleTime;
  }

  function setPublicSaleTime(uint256 publicSaleTime_) external onlyOwner {
    _publicSaleTime = publicSaleTime_;
  }
}