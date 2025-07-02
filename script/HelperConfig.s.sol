// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address owner;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getAnlivEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({owner: 0x7eF78e0ef51A18Ce23269707CA3A256b69F884c1});
    }

    function getMainnetEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({owner: 0x7eF78e0ef51A18Ce23269707CA3A256b69F884c1});
    }

    function getAnlivEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266});
        // 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    }
}
