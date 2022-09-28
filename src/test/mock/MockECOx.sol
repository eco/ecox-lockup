// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC1820RegistryUpgradeable} from "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/introspection/IERC1820RegistryUpgradeable.sol";
import {ERC20} from "../../../lib/solmate/src/tokens/ERC20.sol";
import {IECOx} from "../../interfaces/IECOx.sol";
import {MockPolicy} from "./MockPolicy.sol";
import {MockLockup} from "./MockLockup.sol";

contract MockECOx is IECOx, ERC20 {
    address public policy;
    IERC1820RegistryUpgradeable internal constant ERC1820 =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {
        address lockup = address(new MockLockup(address(this)));
        policy = address(new MockPolicy(lockup));
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
