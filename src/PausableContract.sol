// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {PausableUpgradable} from "@openzeppelin-upgrades/contracts/utils/PausableUpgradable.sol";
import {Ownable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradable.sol";
import {Ownable} from "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

import {IPausableContract} from "./IPausableContract.sol";


abstract contract Pausable is PausableUpgradable, OwnableUpgradable, IPausable {

    address public pauseController;

    event PauseControllerUpdated(address indexed newController);

    // TODO: Make initializable version for proxied contracts
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {

    }

    modifier onlyPauseController {
        require(msg.sender == pauseController);
        _;
    }

    function pause() external virtual onlyPauseController {
        _pause();
    }

    function unpause() external virtual onlyPauseController {
        _unpause();
    }

    function updatePauseController(address _newController) external virtual onlyPauseController {
        pauseController = _newController;
        emit PauseControllerUpdated(_newController);
    }
}