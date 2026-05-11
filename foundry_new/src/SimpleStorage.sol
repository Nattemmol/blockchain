// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public value;

    struct Person {
        string name;
        uint256 age;
    }

    function setValue(uint256 _value) public {
        value = _value;
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function createPerson(string memory _name, uint256 _age) public pure returns (Person memory) {
        return Person({name: _name, age: _age});
    }

    function getPerson(Person memory _person) public pure returns (string memory, uint256) {
        return (_person.name, _person.age);
    }
    
    
}
