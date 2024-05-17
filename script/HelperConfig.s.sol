// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

/**
 * @title Helper script for DeployFundMe
 * @author Patrick Collins and Sooper Fi
 * @notice
 *  1. Deploy mocks when we are on a local anvil chain
 *    - otherwise, get existing contract address from the LIVE network
 *
 *  2. Keep track of a contract's address across multiple chains
 *    - e.g. Sepolia ETH/USD, mainnet ETH/USD, etc.
 */
contract HelperConfig is Script {
    // keep track of which network we're currently on
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    /**
     * Stores address of the Chainlink ETH/USD price feed contract.
     */
    struct NetworkConfig {
        address priceFeed;
    }

    /**
     * Every time we deploy a new HelperConfig() script, constructor()
     *      updates activeNetworkConfig accordingly.
     *
     *      @dev Sepolia chainid=11155111; mainnet chainid=1
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

    /**
     * Getter for the Sepolia ETH/USD contract address.
     */
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    /**
     * Getter for the mainnet ETH/USD contract address.
     */
    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    /**
     * Checks if mock contract has already been deployed, deploys them
     *     and returns the mock contract address on anvil if needed.
     */
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
