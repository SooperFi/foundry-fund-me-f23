// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

/**
 * @title
 * @author Patrick Collins and Sooper Fi
 * @notice
 * @dev
 */
contract FundFundMe is Script {
    uint256 constant SEND_VAL = 0.01 ether;

    /**
     *
     */
    function fundFundMe(address mostRecentlyDeployed) public {
        // use this script contract to fund() a FundMe contract
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VAL}();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VAL);
    }

    /**
     *
     */
    function run() external {
        // look in broadcast folder (using chainid) >> run_latest.json >> get address of last contract deployed
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentlyDeployed);
    }
}

/**
 * Getter for the mainnet ETH/USD contract address.
 */
contract WithdrawFundMe is Script {
    /**
     *
     */
    function withdrawFundMe(address mostRecentlyDeployed) public {
        // use this script contract to withdraw() from a FundMe contract
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    /**
     *
     */
    function run() external {
        // look in broadcast folder (using chainid) >> run_latest.json >> get address of last contract deployed
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentlyDeployed);
    }
}
