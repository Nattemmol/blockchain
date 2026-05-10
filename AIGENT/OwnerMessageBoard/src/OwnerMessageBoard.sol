// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnerMessageBoard {
    address public owner;
    string public message;

    event MessageUpdated(string newMessage);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function updateMessage(string memory _message) public onlyOwner {
        message = _message;
        emit MessageUpdated(_message);
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}