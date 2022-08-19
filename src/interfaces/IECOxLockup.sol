// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IECOxLockup {
    function deposit(uint256 _amount) external;

    function delegate(address delegatee) external;

    function withdraw(uint256 _amount) external;

    function undelegate() external;
}
