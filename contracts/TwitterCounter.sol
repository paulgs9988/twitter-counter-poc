// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TwitterCounter {
    uint256 public count;
    address public safeAddress;
    address public owner;
    
    event CounterUpdated(uint256 newCount, uint256 timestamp);
    
    constructor(address _safeAddress) {
        require(_safeAddress != address(0), "Invalid safe address");
        safeAddress = _safeAddress;
        owner = msg.sender;
        count = 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function updateCounter() external {
        require(msg.sender == safeAddress, "Only safe can update");
        count += 1;
        emit CounterUpdated(count, block.timestamp);
    }
    
    function getCount() external view returns (uint256) {
        return count;
    }
    
    function updateSafeAddress(address _newSafeAddress) external onlyOwner {
        require(_newSafeAddress != address(0), "Invalid address");
        safeAddress = _newSafeAddress;
    }
}