// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsBank {
    uint256 public balance;
    uint256 public totalBalance;
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public lastWithdrawalTime;
    address public owner;
    uint256 public constant MIN_DEPOSIT = 1 ether;
    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit must be at least 1 ether");
        balance += msg.value;
        totalBalance += msg.value;
        userBalances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can withdraw");
        require(amount <= balance, "Insufficient balance");
        balance -= amount;
        totalBalance -= amount;
        userBalances[msg.sender] -= amount;
    }

    function emergencyWithdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        balance = 0;
        totalBalance = 0;
        userBalances[msg.sender] = 0;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function getTotalBalance() public view returns (uint256) {
        return totalBalance;
    }
    

}