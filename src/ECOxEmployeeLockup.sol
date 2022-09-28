pragma solidity 0.8.15;

import {ECOxVestingVault} from "./ECOxVestingVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";

contract ECOxEmployeeLockup is ECOxVestingVault {

    uint256 cliffTimestamp;

    function initialize(address admin) public override initializer {
        ECOxVestingVault.initialize(admin);
        cliffTimestamp = this.timestamps()[0];
    }

    function vestedOn(uint256 timestamp) public override view returns (uint256 amount){
        return timestamp >= cliffTimestamp ? token().balanceOf(address(this)) : 0;
    }


}