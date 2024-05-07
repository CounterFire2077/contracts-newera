// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../core/HasSignature.sol";
import "../utils/TimeChecker.sol";


contract TreasureHunt is HasSignature, ReentrancyGuard, TimeChecker{
  mapping(address => mapping(uint256 => uint256)) public checkinHistory;
  mapping(address => mapping(uint256 => uint256)) public exploreHistory;
  mapping(address => mapping(uint256 => uint256)) public enhanceHistory;
  mapping(address => mapping(uint256 => uint256)) public claimTaskHistory;
  mapping(address => mapping(uint256 => uint256)) public openBoxHistory;
  uint256 private immutable _CACHED_CHAIN_ID;
  address private immutable _CACHED_THIS;
  address private verifier;

  bool public isPaused = false;

  event ActionEvent(
    address indexed user,
    uint256 indexed action,
    uint256 value
  );

  event StateUpdated(bool isPaused);
  event VerifierUpdated(address indexed verifier);

  constructor() {
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_THIS = address(this);
  }

  modifier whenNotPaused() {
    require(!isPaused, "TreasureHunt: paused");
    _;
  }

  function updatePaused(bool _isPaused) external onlyOwner {
    isPaused = _isPaused;
    emit StateUpdated(_isPaused);
  }

  /**
   * @dev update verifier address
   */
  function updateVerifier(address _verifier) external onlyOwner {
    require(_verifier != address(0), "TreasureHunt: address can not be zero");
    verifier = _verifier;
    emit VerifierUpdated(_verifier);
  }
  
  // daily checkin
  function dailyCheckin() external whenNotPaused {
    address user = _msgSender();
    uint256 day = block.timestamp / 1 days;
    require(checkinHistory[user][day] == 0, "TreasureHunt: already checked in");
    checkinHistory[user][day] = 1;
    emit ActionEvent(user, 1, day);
  }

  // explore
  function explore(
    uint256 step
  ) external whenNotPaused {
    address user = _msgSender();
    exploreHistory[user][step] = 1;
    emit ActionEvent(user, 2, step);
  } 

  // enhance box
  function enhanceBox(
    uint256 boxId
  ) external whenNotPaused {
    address user = _msgSender();
    require(enhanceHistory[user][boxId] == 0, "TreasureHunt: already enhanced");
    enhanceHistory[user][boxId] = 1;
    emit ActionEvent(user, 3, boxId);
  } 

  // open box
  function openBox(
    uint256 boxId
  ) external whenNotPaused {
    address user = _msgSender();
    require(openBoxHistory[user][boxId] == 0, "TreasureHunt: already opened");
    openBoxHistory[user][boxId] = 1;
    emit ActionEvent(user, 4, boxId);
  }

  // claim task reward
  function claimTaskReward(
    uint256 taskId
  ) external whenNotPaused{
    address user = _msgSender();
    require(claimTaskHistory[user][taskId] == 0, "TreasureHunt: already claimed");
    claimTaskHistory[user][taskId] = 1;
    emit ActionEvent(user, 5, taskId);
  } 

  function generalAction(
    uint256 actionType,
    uint256 val,
    uint256 signTime,
    uint256 saltNonce,
    bytes calldata signature
  ) external nonReentrant whenNotPaused timeValid(signTime){
    address user = _msgSender();
    bytes32 criteriaMessageHash = getMessageHash(
      user,
      actionType,
      val,
      _CACHED_THIS,
      _CACHED_CHAIN_ID,
      signTime,
      saltNonce
    );
    checkSigner(verifier, criteriaMessageHash, signature);
    if (actionType == 1) {
      require(checkinHistory[user][val] == 0, "TreasureHunt: already checked in");
      checkinHistory[user][val] = 1;
    } else if (actionType == 2) {
      require(exploreHistory[user][val] == 0, "TreasureHunt: already explored");
      exploreHistory[user][val] = 1;
    } else if (actionType == 3) {
      require(enhanceHistory[user][val] == 0, "TreasureHunt: already enhanced");
      enhanceHistory[user][val] = 1;
    } else if (actionType == 4) {
      require(openBoxHistory[user][val] == 0, "TreasureHunt: already opened");
      openBoxHistory[user][val] = 1;
    } else if (actionType == 5) {
      require(claimTaskHistory[user][val] == 0, "TreasureHunt: already claimed");
      claimTaskHistory[user][val] = 1;
    } else {
      revert("TreasureHunt: invalid action type");
    }
    emit ActionEvent(user, actionType, val);
  }

  function getMessageHash(
    address _user,
    uint256 _type,
    uint256 _val,
    address _contract,
    uint256 _chainId,
    uint256 _signTime,
    uint256 _saltNonce
  ) public pure returns (bytes32) {
    bytes memory encoded = abi.encodePacked(
      _user,
      _type,
      _val,
      _contract,
      _chainId,
      _signTime,
      _saltNonce
    );
    return keccak256(encoded);
  }
}
