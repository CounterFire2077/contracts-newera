// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TimeChecker is Ownable {
  uint256 public duration;
  uint256 public minDuration;

  event DurationUpdated(uint256 indexed duration);

  constructor() {
    duration = 1 days;
    minDuration = 30 minutes;
  }

  /**
   * @dev Check if the time is valid
   */
  modifier timeValid(uint256 time) {
    require(
      time + duration > block.timestamp,
      "expired, please send another transaction with new signature"
    );
    _;
  }


  /**
   * @dev Change duration value
   */
  function updateDuation(uint256 valNew) external onlyOwner {
    require(valNew > minDuration, "duration too short");
    duration = valNew;
    emit DurationUpdated(valNew);
  }
}
