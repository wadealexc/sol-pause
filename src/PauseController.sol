// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IPausable} from "./IPausable.sol";

/**
 * @title Used to maintain pausable contracts and the addresses that can pause them
 * 
 * This contract maintains a list of pausable contracts (`pausables`). The two primary
 * methods in this contract, `pauseAll()` and `unpauseAll()` iterate over `pausables`
 * and call `pause()` or `unpause()` on each respectively.
 *
 * @dev Only addresses in the `isPauser` mapping (or the contract owner) may call `pauseAll()`.
 * Only the owner may call `unpauseAll()`. The owner may also:
 * - update `isPauser` addresses (via `setPauser`)
 * - add/remove `pausable` contracts (via `addPausables` and `removePausables`)
 * - trigger a migration to a new `PauseController` contract (via `migrateAll`)
 * 
 * NOTE: For simplicity, this contract is not meant to be behind a proxy - its primary 
 * upgrade mechanism is via `migrateAll`.
 *
 * See the README for more info!
 */
contract PauseController is Ownable {

    using EnumerableSet for *;

    /// @dev These addresses can trigger a pause. Only the owner may unpause.
    mapping(address => bool) public isPauser;

    /// @dev All the contracts the PauseController can pause/unpause
    EnumerableSet.AddressSet pausables;

    // Events for primary pause/unpause/migration methods
    event PauseTriggered(address indexed caller);
    event UnpauseTriggered();
    event MigrationTriggered(address indexed newController);

    // Events for secondary methods used to update pausers and pausable contracts.
    event PauserUpdated(address indexed pauser, bool canPause);
    event PausableContractAdded(IPausable indexed p);
    event PausableContractRemoved(IPausable indexed p);

    constructor(address[] memory _pausers) {
        for(uint i = 0; i < _pausers.length; i++) {
            _setPauser(_pausers[i], true);
        }
    }
    
    /// @dev The owner is a de-facto pauser and may also call `pauseAll()`
    modifier onlyPauser {
        require(isPauser[msg.sender] || msg.sender == owner());
        _;
    }

    /**
     * @notice `pauseAll()` is used to trigger a pause in all pausable contracts.
     * Only pausers or the contract owner may call this method. Only the owner
     * may unpause (via `unpauseAll()`).
     * @dev This method iterates over `pausables` and calls `pause()` on each.
     * This method ignores reverts in order to keep things simple, as well as
     * to be sure its primary function (call the `pause()` method on all targets)
     * is carried out.
     *
     * Outside of simplification, another reason to ignore reverts here is so that
     * PauseController can be used with OpenZeppelin Pausable, whose pause function
     * will revert if the contract is already paused. In this case, this function
     * prefers to continue attempting to pause the rest of the pausable contracts.
     *
     * Unpausing is limited to onlyOwner to reduce the scope of the pauser role.
     * See the README for details.
     */
    function pauseAll() external virtual onlyPauser {
        uint length = pausables.length();

        for (uint i = 0; i < length;) {
            try IPausable(pausables.at(i)).pause() { } catch { }

            unchecked { i++; }
        }

        emit PauseTriggered(msg.sender);
    }

    /**
     * @notice `unpauseAll()` is used to unpause all pausable contracts. Only the
     * contract owner may call this method.
     * @dev This method iterates over `pausables` and calls `unpause()` on each.
     * This method ignores reverts in order to keep things simple, as well as
     * to be sure its primary function (call the `unpause()` method on all targets)
     * is carried out.
     *
     * This method is restricted to onlyOwner to reduce the scope of the pauser
     * role. See the README for details.
     */
    function unpauseAll() external virtual onlyOwner {
        uint length = pausables.length();

        for (uint i = 0; i < length;) {
            try IPausable(pausables.at(i)).unpause() { } catch { }

            unchecked { i++; }
        }

        emit UnpauseTriggered();
    }

    /**
     * @notice `migrateAll(address)` is used to change the PauseController
     * address in all pausable contracts. This can be used either to upgrade to a new
     * PauseController, or to "burn" the ability to pause. Only the owner may call this
     * method.
     * @dev This method iterates over `pausables` and calls `updatePauseController` on
     * each.
     * 
     * Unlike `pauseAll()` and `unpauseAll()`, this method will FAIL if any calls revert.
     * This is to help ensure a migration is performed across all contracts simultaneously.
     * 
     * This method also does NOT check that `_newController` is a valid address/contract. 
     * This is to support updating to address(0) to "burn" pausability.
     */
    function migrateAll(address _newController) external virtual onlyOwner {
        uint length = pausables.length();

        for (uint i = 0; i < length;) {
            IPausable(pausables.at(i)).updatePauseController(_newController);

            unchecked { i++; }
        }
        
        emit MigrationTriggered(_newController);
    }

    /// @dev Allows the owner to add or remove a pauser from `isPauser`
    function setPauser(address _pauser, bool _canPause) external virtual onlyOwner {
        _setPauser(_pauser, _canPause);
    }

    /**
     * @notice Allows the owner to add pausable contracts. Future calls to
     * `pauseAll()` and `unpauseAll()` will include a call to the added contract.
     * @dev This method will ignore entries that are already in the set of pausables.
     * When adding pausable contracts, remember to:
     * - Check the gas cost required to call `pauseAll` and `unpauseAll`
     * - Check that pausable contracts are initialized and will pause/unpause when called
     *   by this contract
     */
    function addPausables(IPausable[] calldata _pausables) external virtual onlyOwner {
        uint length = _pausables.length;
        for (uint i = 0; i < length;) {
            _addPausable(_pausables[i]);

            unchecked { i++; }
        }
    }

    /**
     * @notice Allows the owner to remove pausable contracts
     * @dev This method will ignore entries that aren't in the set
     */
    function removePausables(IPausable[] calldata _pausables) external virtual onlyOwner {
        uint length = _pausables.length;
        for (uint i = 0; i < length;) {
            _removePausable(_pausables[i]);

            unchecked { i++; }
        }
    }

    //// External: View

    /// @dev Returns a list of pausable contracts
    function getPausables() external virtual view returns (address[] memory) {
        return pausables.values();
    }

    //// Internal

    function _setPauser(address _pauser, bool _canPause) internal virtual {
        require(_pauser != address(0));
        isPauser[_pauser] = _canPause;
        emit PauserUpdated(_pauser, _canPause);
    }

    function _addPausable(IPausable _pausable) internal virtual {
        require(address(_pausable) != address(0));
        bool added = pausables.add(address(_pausable));
        if (added) {
            emit PausableContractAdded(_pausable);
        }
    }

    function _removePausable(IPausable _pausable) internal virtual {
        bool removed = pausables.remove(address(_pausable));
        if (removed) {
            emit PausableContractRemoved(_pausable);
        }
    }
}
