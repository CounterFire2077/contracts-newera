// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BEBadgeV2 is Ownable, ERC721Enumerable, ERC721Burnable {
  string private _baseTokenURI = "";
  uint256 public immutable supplyLimit;
  uint256 private _tokenIndex;
  mapping(address => bool) public minters;

  // ============ Events ============
  event MetaAddressUpdated(address indexed metaAddress);
  event MinterUpdated(address indexed minter, bool support);
  
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _supplyLimt
  ) ERC721(_name, _symbol) {
    require(_supplyLimt > 0, "Supply limit must be greater than 0");
    supplyLimit = _supplyLimt;
  }


  /**
   * @dev Safely mints a new token and assigns it to the specified address.
   * Only the account with the minter permission can call this function.
   * tokenId begin with 1. 
   * @param _to The address to which the newly minted token will be assigned.
   */
  function safeMint(address _to) external onlyMinter returns (uint256){
    require(_tokenIndex < supplyLimit, "Exceeds the total supply");
    uint256 tokenId = ++_tokenIndex;
    _safeMint(_to, tokenId);
    return tokenId;
  }

  /**
   * @dev Set token URI
   */
  function updateBaseURI(
    string calldata baseTokenURI
  ) external onlyOwner() {
    _baseTokenURI = baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  

  /**
   * @dev See {IERC165-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
  }
  
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
  /**
   * @dev Updates the minters mapping to allow or disallow a specific address to mint tokens.
   * Only the contract owner can call this function.
   * @param _address The address to update the minting permission for.
   * @param _support A boolean indicating whether the address should be allowed to mint tokens or not.
   */
  
  function updateMinters(address _address, bool _support) external onlyOwner {
    minters[_address] = _support;
    emit MinterUpdated(_address, _support);
  }

  modifier onlyMinter() {
    require(minters[_msgSender()], "Address does not have the minter permission");
    _;
  }
}
