// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {SavingsBank} from "../src/SavingsBank.sol";

contract SavingsBankScript is Script {
    function run() external {
        vm.startBroadcast();
        new SavingsBank();
        vm.stopBroadcast();
    }
}