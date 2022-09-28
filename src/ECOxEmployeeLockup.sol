pragma solidity 0.8.15;

import {ECOxVestingVault} from "./ECOxVestingVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";

contract ECOxEmployeeLockup is ECOxVestingVault {

    // uint256 public cliffTimestamp;

    // function initialize(address admin) public override initializer {
    //     ECOxVestingVault.initialize(admin);
    //     cliffTimestamp = this.timestamps()[0];
    // }

    function vestedOn(uint256 timestamp) public override view returns (uint256 amount){
        return timestamp >= this.timestamps()[0] ? token().balanceOf(address(this)) : 0;
    }

    // total to be dripped - what is accessible to employee right now?
    function unvested() public view override returns (uint256) {
        return this.amounts()[0] - vested();
    }


}