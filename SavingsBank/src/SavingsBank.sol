// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingsBank {
    mapping(address => uint256) public balances;
    uint256 public constant MIN_DEPOSIT = 0.01 ether;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT, "Minimum deposit is 0.01 ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function checkBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }
}