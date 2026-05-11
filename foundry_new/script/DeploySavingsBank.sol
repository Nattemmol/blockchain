/*
4.Deployment

* Write a deployment script in the `script/` folder.
* Deploy the contract locally.
* Confirm deployment was successful.

 Bonus Challenge

Add one of the following:
* A minimum deposit requirement.
* A withdrawal cooldown (e.g., users can only withdraw once every 1 minute).
* Owner-only emergency withdraw function.*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {SavingsBank} from "../src/SavingsBank.sol";

contract DeploySavingsBank is Script {
    function run() external returns (SavingsBank) {
        vm.startBroadcast();
        SavingsBank savingsBank = new SavingsBank();
        vm.stopBroadcast();
        return savingsBank;
    }
}