// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PausableUpgradeable} from "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";

import {IPausable} from "./IPausable.sol";

/**
 * @title Can be inherited from to add support for pausability via pauseController
 *
 * This contract inherits from openzeppelin's PausableUpgradeable and is compatible 
 * with standard proxy patterns. You can use the `whenNotPaused()` modifier in child 
 * contracts to enable pausability.
 */
abstract contract Pausable is PausableUpgradeable, IPausable {

    address public pauseController;

    event PauseControllerUpdated(address indexed newController);

    function _initializePausable(address _pauseController) internal onlyInitializing {
        pauseController = _pauseController;
    }

    modifier onlyPauseController {
        require(msg.sender == pauseController);
        _;
    }

    /**
     * @dev Allows the pauseController to pause methods using the `whenNotPaused()` modifier
     * Note that this method reverts if the contract is already paused, but
     * the PauseController implementation ignores this.
     */
    function pause() external virtual onlyPauseController {
        _pause();
    }

    /**
     * @dev Allows the pauseController to unpause methods using the `whenNotPaused()` modifier
     * Note that this method reverts if the contract is already paused, but
     * the PauseController implementation ignores this.
     */
    function unpause() external virtual onlyPauseController {
        _unpause();
    }

    /**
     * @dev Allows the pauseController to migrate to a new address
     */
    function updatePauseController(address _newController) external virtual onlyPauseController {
        pauseController = _newController;
        emit PauseControllerUpdated(_newController);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
     uint[49] private __gap;
}