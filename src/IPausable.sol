// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPausable {
    function pause() external;
    function unpause() external;
    function updatePauseController(address) external;
    function pauseController() external view returns (address);
}