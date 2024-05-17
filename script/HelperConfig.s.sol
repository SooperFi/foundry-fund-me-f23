// SPDX-License-Identifier: MIT

/**
 *  1. Deploy mocks when we are on a local anvil chain
 *  2. Keep track of contract address across multiple chains
 *    - e.g. Sepolia ETH/USD, mainnet ETH/USD, etc
 */

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

/**
 *  if we are on a local anvil chain, we deploy mock contracts
 *  otherwise, we grab the existing contract address from the LIVE network
 */
contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig; // returns whatever current network we are on

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed contract address
    }

    /**
     * every time we deploy a HelperConfig() script, the constructor() call
     * updates the activeNetworkConfig variable accordingly
     */
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        // 1. deploy mock contract(s) on local anvil chain
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        // 2. return the mock contract(s) address
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
