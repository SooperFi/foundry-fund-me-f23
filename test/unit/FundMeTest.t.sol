// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

/**
 * @title FundMe.sol Testcases
 * @author Patrick Collins and Sooper Fi
 * @notice This contract provides high-coverage testing of
 *         FundMe.sol's various methods.
 *
 * @dev use 'forge test --match-test <t_name>' to
 *      specify a single testcase to run
 * @dev imports DeployFundMe script to test deploy
 *      script
 * @dev each test runs setUp() before executing
 */

contract FundMeTest is Test {
    FundMe fundMe;

    uint256 constant GAS_PRICE = 1;
    address USER = makeAddr("user");
    uint256 constant SEND_VAL = 0.1 ether;
    uint256 constant INITIAL_BAL = 10 ether;

    /**
     * Instantiates fundMe state variable with a new FundMe contract.
     *
     *     IMPORTANT: FundMeTest is the caller of constructor()
     *     in FundMe.sol... so fundMe's i_owner address will be
     *     the FundMeTest contract address.
     */
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMeScript = new DeployFundMe();
        fundMe = deployFundMeScript.run();
        vm.deal(USER, INITIAL_BAL);
    }

    /**
     * Check MINIMUM_USD() is expected value (5e18).
     */
    function testCheckMinAmount() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    /**
     * Check that fundMe's i_owner is the deployer.
     */
    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
        // assertEq(fundMe.i_owner(), address(this));
    }

    /**
     * Simple check that fundMe's price feed is the expected version.
     *
     *     IMPORTANT: Be extremely mindful of which environment tests
     *     are executed in. Foundry defaults to a TEMPORARY local anvil
     *     chain, so this chain won't have a price feed contract deployed
     *     to properly call getVersion() on.
     *
     *     @dev use 'forge test --fork-url <rpc_url>' to run forked tests
     */
    function testPriceFeedVersionIsAccurate() public view {
        uint256 v = fundMe.getVersion();
        assertEq(v, 4);
    }

    /**
     * Check if calling fund() with no value argument fails; calling
     *     fund() with less than 5e18 wei MUST revert.
     *
     *     @dev uses Foundry cheatcode 'vm.expectRevert()'; failure
     *          of the next line means a successful test.
     */
    function testIfNotEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    /**
     * Test fund() common case; check funder address and amountFunded
     *     is properly mapped in addressToAmountFunded.
     *
     *     @dev uses Foundry cheatcode 'vm.prank()'; revert if next
     *          tx is NOT sent by the specified address.
     *
     *     @dev specified address for vm.prank() is test USER, and
     *          they fund() with SEND_VAL amt of ETH.
     *
     */
    function testFundUpdatesFundedMapping() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VAL}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VAL);
    }

    /**
     * Test fund() common case; check funder address is properly
     *     added to funders array.
     *
     *     @dev uses Foundry cheatcode 'vm.prank()'; revert if next
     *          tx is NOT sent by the specified address.
     *
     *     @dev specified address for vm.prank() is test USER, and
     *          they fund() with SEND_VAL amt of ETH.
     */
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VAL}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    /**
     * "Helper" for tests that start with vm.prank() >> fundMe.fund()
     */
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VAL}();
        _;
    }

    /**
     * Test only i_owner address (contract deployer) can successfully
     *     withdraw(); ensures onlyOwner modifier works properly.
     *
     *     @dev uses Foundry cheatcode 'vm.prank()'; revert if next
     *          tx is NOT sent by the specified address.
     *
     *     @dev uses Foundry cheatcode 'vm.expectRevert()'; failure
     *          of the next line means a successful test.
     *
     *     @dev specified address for vm.prank() is test USER, and
     *          they fund() with SEND_VAL amt of ETH; expected failure
     *          is fundMe.withdraw() call by the test USER.
     */
    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    /**
     * Test withdraw() edge case with only one funder.
     */
    function testSingleFunderWithdraw() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft(); // built-in Solidity function which says how much gas is left in the tx call
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        /* now find difference in gasleft() values */
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // gas used to execute the withdraw() call
        console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    /**
     * Test withdraw() edge case with only one funder.
     *
     *     @dev uses Foundry "standard cheatcode" hoax() to
     *          simulate vm.prank() >> vm.deal()
     *     @dev must use uint160 for address() casting
     */
    function testMultipleFunderWithdraw() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // using i=0 may revert, always start i=1
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VAL);
            fundMe.fund{value: SEND_VAL}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testMultipleFunderWithdrawCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // using i=0 may revert, always start i=1
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VAL);
            fundMe.fund{value: SEND_VAL}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
