pragma solidity 0.8.15;

import {ECOxLockupVault} from "./ECOxLockupVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

contract ECOxEmployeeLockup is ECOxLockupVault {
    function vestedOn(uint256 timestamp) public view override returns (uint256 amount) {
        return timestamp >= this.timestamps()[0] ? token().balanceOf(address(this)) + IERC20Upgradeable(lockup).balanceOf(address(this)): 0;
    }
}
