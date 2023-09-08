// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PauserRegistry is Ownable {

    mapping(address => bool) public isPauser;

    constructor(address[] memory _pausers, address _unpauser) {
        for(uint i = 0; i < _pausers.length; i++) {

        }
    }

    function _setPauser(address _pauser, bool _canPause) internal virtual {
        require(_pauser != address(0));
        isPauser[_pauser] = _canPause;
    }

    function _setUnpauser(address _new)
}
