// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../core/HasSignature.sol";
import "../utils/TimeChecker.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * Contract for activity NFT claim.
 */
interface IClaimAbleNFT {
  function safeMint(
    address to
  ) external returns (uint256);
}

contract NFTClaimer is HasSignature, TimeChecker, ReentrancyGuard{
  uint256 private immutable _CACHED_CHAIN_ID;
  address private immutable _CACHED_THIS;
  address public signer;
  uint256 public startTime;
  uint256 public endTime;
  mapping(address => bool) public tokenSupported;
  mapping(address => uint256) public claimHistory;

  event NFTClaimed(
    address indexed nftAddress,
    address indexed to,
    uint256 tokenId,
    uint256 nonce
  );
  event NFTSupportUpdated(address indexed nftAddress, bool support);
  event SignerUpdated(address indexed signer);
  event StartTimeUpdated(uint256 indexed startTime);
  event EndTimeUpdated(uint256 indexed endTime);

  constructor() {
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_THIS = address(this);
  }

  function updateTokenSupport(address nftToken, bool support) external onlyOwner {
    tokenSupported[nftToken] = support;
    emit NFTSupportUpdated(nftToken, support);
  }

  function updateStartTime(uint256 _startTime) external onlyOwner {
    startTime = _startTime;
    emit StartTimeUpdated(_startTime);
  }

  function updateEndTime(uint256 _endTime) external onlyOwner {
    endTime = _endTime;
    emit EndTimeUpdated(_endTime);
  }
  

  /**
   * @dev update signer
   * @param account new signer address
   */
  function updateSigner(address account) external onlyOwner {
    require(account != address(0), "NFTClaimer: address can not be zero");
    signer = account;
    emit SignerUpdated(account);
  }

  /**
   * @dev claim NFT
   * Get whitelist signature from a third-party service, then call this method to claim NFT
   * @param nftAddress NFT address
   * @param signTime sign time
   * @param saltNonce nonce
   * @param signature signature
   */
  function claim(
    address nftAddress,
    uint256 signTime,
    uint256 saltNonce,
    bytes calldata signature
  ) external signatureValid(signature) timeValid(signTime) nonReentrant {
    require(block.timestamp >= startTime, "NFTClaimer: not started");
    require(block.timestamp <= endTime, "NFTClaimer: already ended");
    require(tokenSupported[nftAddress], "NFTClaimer: unsupported NFT");
    address to = _msgSender();
    require(claimHistory[to] == 0, "NFTClaimer: already claimed");
    bytes32 criteriaMessageHash = getMessageHash(
      to,
      nftAddress,
      signTime,
      saltNonce
    );
    checkSigner(signer, criteriaMessageHash, signature);
    uint256 tokenId = IClaimAbleNFT(nftAddress).safeMint(to);
    claimHistory[to] = tokenId;
    _useSignature(signature);
    emit NFTClaimed(nftAddress, to, tokenId, saltNonce);
  }

  function getMessageHash(
    address _to,
    address _address,
    uint256 _signTime,
    uint256 _saltNonce
  ) public view returns (bytes32) {
    bytes memory encoded = abi.encodePacked(
      _to,
      _address,
      _signTime,
      _CACHED_CHAIN_ID,
      _CACHED_THIS,
      _saltNonce
    );
    return keccak256(encoded);
  }
}
