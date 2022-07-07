// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC1820RegistryUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820RegistryUpgradeable.sol";
import {IECOx} from "../../interfaces/IECOx.sol";

contract MockPolicy {
    IERC1820RegistryUpgradeable internal constant ERC1820 =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 internal constant ERC1820_ACCEPT_MAGIC =
        keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

    bytes32 internal constant LOCKUP_HASH =
        keccak256(abi.encodePacked("ECOxLockup"));

    constructor(address lockup) {
        ERC1820.setInterfaceImplementer(address(this), LOCKUP_HASH, lockup);
    }
}
