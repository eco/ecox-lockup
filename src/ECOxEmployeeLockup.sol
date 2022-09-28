pragma solidity 0.8.15;

import {ECOxVestingVault} from "./ECOxVestingVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";

contract ECOxEmployeeLockup is ECOxVestingVault {

    function vestedOn(uint256 timestamp) public override view returns (uint256 amount){
        return timestamp >= this.timestamps()[0] ? token().balanceOf(address(this)) : 0;
    }

    function unvested() public view override returns (uint256) {
        return token().balanceOf(address(this)) - vested();
    }


}