// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {SimpleVoting} from "../src/SimpleVoting.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySimpleVoting is Script {
    function run() external returns (SimpleVoting) {
        HelperConfig helperConfig = new HelperConfig();

        address owner = helperConfig.activeNetworkConfig();

        // deploy from needed address on current chain
        vm.startBroadcast(owner);
        SimpleVoting simpleVoting = new SimpleVoting();
        vm.stopBroadcast();

        return simpleVoting;
    }
}
