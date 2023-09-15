// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";

import {Pausable} from "../src/Pausable.sol";

/**
 * @title Barebones example demonstrating pausable contract's use of modifiers
 * 
 * See the README for details.
 */
contract LendingPool is Pausable, OwnableUpgradable {

    constructor() {
        _disableInitializers();
    }

    function initialize(address _pauseController) external initializer {
        __Ownable_init();
        _initializePausable(_pauseController);
    }

    /**
     * @notice onlyOwner / admin functions
     * @dev Admin functions should not be locked when the contract is paused,
     * as these methods should allow the admin to configure the contract in
     * any state.
     * 
     * It's even possible that config methods like these allow for patching
     * issues while the contract is paused (without the need for a risky upgrade).
     * 
     * For example, if (while paused) the root cause of an issue is determined
     * to be a "faulty loan strategy," the `disableLoanStrategy()` can patch the
     * issue immediately, without the need to unpause or perform an upgrade.
     *
     * The point of the pause is to give yourself the time to correctly determine
     * these root causes and decide on the best course of action - without the
     * time pressure of live, buggy contracts.
     */
    function setLoanFees(uint _newFees) external onlyOwner {
        // logic goes here
    }

    function disableLoanStrategy(address _strategy) external onlyOwner {
        // logic goes here
    }

    /**
     * @notice User-facing functions 
     * @dev These should be locked when the contract is paused to prevent any 
     * further state changes in the event a bug is discovered.
     * 
     * These methods can be unpaused if it is determined to be safe; otherwise
     * admin functions or a contract upgrade can be used to first patch the bug
     * and then unpause.
     */
    
    function lend() external notPaused {
        // logic goes here
    }

    function borrow() external notPaused {
        // logic goes here
    }

    function repay() external notPaused {
        // logic goes here
    }
}