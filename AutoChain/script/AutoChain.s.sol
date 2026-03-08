// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {AutoChain} from "../src/AutoChain.sol";

contract AutoChainScript is Script {
    function run() external {
        vm.startBroadcast();
        new AutoChain();
        vm.stopBroadcast();
    }
}