// SPDX-License-Identifier: GPL-3.0

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC721Enumerable } from './base/ERC721Enumerable.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { IAssetStore } from './interfaces/IAssetStore.sol';
import { ERC721 } from './base/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { Base64 } from 'base64-sol/base64.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract PrideSquiggle is INounsToken, Ownable, ERC721Enumerable {
  using Strings for uint256;

  // The internal noun ID tracker
  uint256 private _currentNounId;

  // developer address.
  address public developer;

  // mint limit
  uint256 public limit;

  // description
  string public description = "Celebrating Pride Month 2022";

  // The Nouns token URI descriptor
  IAssetStore public assetStore;

  
  // OpenSea's Proxy Registry
  IProxyRegistry public immutable proxyRegistry;

  constructor(
      uint256 _limit,
      address _developer,
      IProxyRegistry _proxyRegistry,
      IAssetStore _assetStore
    ) ERC721('Pride Squiggle 2022', 'PRIDESQUIGGLE22') {
      limit = _limit;
      developer = _developer;
      proxyRegistry = _proxyRegistry;
      assetStore = _assetStore;
      mint();
  }

  /**
    * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
      // Whitelist OpenSea proxy contract for easy trading.
      if (proxyRegistry.proxies(owner) == operator) {
          return true;
      }
      return super.isApprovedForAll(owner, operator);
  }

  /**
    * @notice Anybody can mint, one per wallet.
    */
  function mint() public override returns (uint256) {
    require(balanceOf(msg.sender) == 0, "You already have one.");
    require(_currentNounId < limit, "Sold out.");
    if (_currentNounId % 20 == 2) {
      _mint(owner(), developer, _currentNounId++);
    }
    uint256 tokenId = _currentNounId++;
    _mint(owner(), msg.sender, tokenId);
    emit NounBought(tokenId, msg.sender);
    return tokenId;
  }

  /**
    * @notice Burn a noun.
    */
  function burn(uint256 nounId) public override onlyOwner {
    require(_exists(nounId), 'URI query for nonexistent token');
    _burn(nounId);
    emit NounBurned(nounId);
  }

  /*
    * @notice get next tokenId.
    */
  function getCurrentToken() external view returns (uint256) {                  
      return _currentNounId;
  }

  function generateSVG(uint256 tokenId) public view returns (string memory) {
    return string(_generateSVG(tokenId));
  }

  /**
   * https://www.kapwing.com/resources/official-pride-colors-2021-exact-color-codes-for-15-pride-flags/
   */
  function _generateSVG(uint256 tokenId) internal view returns (bytes memory) {
    bytes memory pack = abi.encodePacked(
      '<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">\n'
      );
        
    return abi.encodePacked(pack,
                            '<g transform="translate(0,0) scale(0.5)">',
                            assetStore.generateSVGPart(1),
                            '</g>'
                            '<g transform="translate(512,0) scale(0.5)">',
                            assetStore.generateSVGPart(2),
                            '</g>'
                            '<g transform="translate(0,512) scale(0.5)">',
                            assetStore.generateSVGPart(3),
                            '</g>'
                            '<g transform="translate(512,512) scale(0.5)">',
                            assetStore.generateSVGPart(4),
                            '</g>'
                            '</svg>');   
  }

  /**
    * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
    * with the JSON contents directly inlined.
    */
  function dataURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
    string memory nounId = tokenId.toString();
    string memory name = string(abi.encodePacked('Asset Test #', nounId));
    string memory image = Base64.encode(_generateSVG(tokenId));
    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
          )
        )
      )
    );
  }

  /**
    * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return dataURI(tokenId);
  }

  /**
    * @notice Set developer.
    * @dev Only callable by the Owner.
    */
  function setDeveloper(address _developer) external onlyOwner {
      developer = _developer;
  }

  /**
    * @notice Set the limit.
    * @dev Only callable by the Owner.
    */
  function setLimit(uint256 _limit) external onlyOwner {
      limit = _limit;
  }

  /**
    * @notice Set the limit.
    * @dev Only callable by the Owner.
    */
  function setDescription(string memory _description) external onlyOwner {
      description = _description;
  }

}

