// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

/**
 * @title FundMe.sol Integrated Testcases
 * @author Patrick Collins and Sooper Fi
 * @notice This contract provides integrated testing of
 *         FundMe.sol's various methods.
 *
 * @dev use 'forge test --match-test <t_name>' to
 *      specify a single testcase to run
 * @dev imports DeployFundMe script to test deploy
 *      script
 * @dev imports FundFundMe script to test fund
 *      script
 * @dev each test runs setUp() before executing
 */

contract FundMeTestIntegration is Test {
    FundMe fundMe;
    /**
     * same flow as DeployFundMe script
     * this is a script of a script
     * were testing the script of the script works
     */
    address USER = makeAddr("user");
    uint256 constant SEND_VAL = 0.1 ether;
    uint256 constant INITIAL_BAL = 10 ether;
    uint256 constant GAS_PRICE = 1;

    /**
     * Use the DeployFundMe script to deploy a new
     *     FundMe contract; deals test USER an
     *     INITIAL_BAL of 10 ether.
     */
    function setUp() external {
        DeployFundMe deployFundMeScript = new DeployFundMe();
        fundMe = deployFundMeScript.run();
        vm.deal(USER, INITIAL_BAL);
    }

    /**
     * Instantiate a FundFundMe script from Interactions.s.sol
     *     then test it properly fund()s the freshly deployed
     *     FundMe contract.
     */
    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
