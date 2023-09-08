// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IPausable} from "./IPausable.sol";

/**
 * @title Ideally this would be called Pausable, but then it couldn't
 * inherit from OpenZeppelin. TODO :(
 */
abstract contract PausableContract is Pausable, IPausable {

    address public pauseController;

    event PauseControllerUpdated(address indexed newController);

    // TODO: Make initializable version for proxied contracts
    constructor(address _pauseController) {
        pauseController = _pauseController;
    }

    modifier onlyPauseController {
        require(msg.sender == pauseController);
        _;
    }

    function pause() external onlyPauseController {
        _pause();
    }

    function unpause() external onlyPauseController {
        _unpause();
    }

    function updatePauseController(address _newController) external onlyPauseController {
        pauseController = _newController;
        emit PauseControllerUpdated(_newController);
    }
}