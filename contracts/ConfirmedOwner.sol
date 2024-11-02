// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ConfirmedOwner {
    address private owner;
    
    constructor(address newOwner) {
        owner = newOwner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }
    
    
}