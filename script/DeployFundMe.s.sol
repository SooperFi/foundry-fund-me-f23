// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title Basic deploy script for FundMe contracts
 * @author Patrick Collins
 * @notice This contract is for deploying new FundMe contracts
 */
contract DeployFundMe is Script {
    /**
     * Runs the script.
     */
    function run() external returns (FundMe) {
        // any computation BEFORE .startBroadcast() is not a real tx
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast(); // start execution {
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast(); // } end execution
        return fundMe;
    }
}
