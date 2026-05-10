// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PersonalCounter {
    mapping(address => uint256) public counters;

    function increment() public {
        counters[msg.sender]++;
    }

    function reset() public {
        counters[msg.sender] = 0;
    }

    function getCounter(address user) public view returns (uint256) {
        return counters[user];
    }
}