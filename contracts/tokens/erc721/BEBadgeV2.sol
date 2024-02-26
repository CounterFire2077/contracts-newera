// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BEBadgeV2 is AccessControl, ERC721Enumerable, ERC721Burnable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  string private _baseTokenURI = "";
  uint256 public immutable supplyLimit;
  uint256 private _tokenIndex;
  uint256 public maxBatchSize = 500;

  // ============ Events ============
  event MetaAddressUpdated(address indexed metaAddress);
  event BatchLimitUpdated(uint256 indexed maxBatchSize);

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _supplyLimt
  ) ERC721(_name, _symbol) {
    _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    supplyLimit = _supplyLimt;
  }

  /**
   * @dev Batch mint tokens and transfer to specified address.
   *
   * Requirements:
   * - Caller must have `MINTER_ROLE`.
   * - The total supply limit should not be exceeded if supplyLimit is greater than zero.
   * - The number of tokenIds offered for minting should not exceed maxBatchSize.
   */

  function batchMint(
    address to,
    uint256 count
  ) external onlyRole(MINTER_ROLE) returns (uint256[] memory) {
    require(count > 0, "count is too small");
    require(count <= maxBatchSize, "Exceeds the maximum batch size");
    require(
      (supplyLimit == 0) || (totalSupply() + count <= supplyLimit),
      "Exceeds the total supply"
    );
    uint256[] memory tokenIds = new uint256[](count);
    for (uint256 i = 0; i < count; i++) {
      _tokenIndex += 1;
      _safeMint(to, _tokenIndex);
      tokenIds[i] = _tokenIndex;
    }
    return tokenIds;
  }

  /**
   * @dev Safely mints a new token and assigns it to the specified address.
   * Only the account with the MINTER_ROLE can call this function.
   * 
   * @param to The address to which the newly minted token will be assigned.
   */
  function safeMint(address to) external onlyRole(MINTER_ROLE) returns (uint256){
    require(
      (supplyLimit == 0) || (totalSupply() < supplyLimit),
      "Exceeds the total supply"
    );
    uint256 tokenId = ++_tokenIndex;
    _safeMint(to, tokenId);
    return tokenId;
  }

  /**
   * @dev Set token URI
   */
  function updateBaseURI(
    string calldata baseTokenURI
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _baseTokenURI = baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  
  /**
    * @dev Updates the maximum batch size for a batch operation.
    * @param valNew The new maximum batch size.
    * Requirements:
    * - The caller must have the DEFAULT_ADMIN_ROLE.
    * - The new batch size must be greater than 0.
    */
  function updateBatchLimit(
    uint256 valNew
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(valNew > 0, "Batch size is too short");
    maxBatchSize = valNew;
    emit BatchLimitUpdated(valNew);
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
    override(ERC721, AccessControl, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
