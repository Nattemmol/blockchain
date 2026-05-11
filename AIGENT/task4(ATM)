// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ATM {

    address public owner;
    bool public paused;

    mapping(address => uint256) private balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "ATM is paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Deposit must be greater than zero");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public whenNotPaused {
        require(amount > 0, "Invalid amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }
}
