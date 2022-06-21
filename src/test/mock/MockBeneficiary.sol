// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
import {ECOxVestingVault} from "../../ECOxVestingVault.sol";

contract MockBeneficiary {
    function claim(ECOxVestingVault vault) public {
        vault.claim();
    }

    function unstake(ECOxVestingVault vault, uint256 amount) public returns (uint256) {
        return vault.unstake(amount);
    }

    function stake(ECOxVestingVault vault, uint256 amount) public {
        vault.stake(amount);
    }

    function delegate(ECOxVestingVault vault, address who) public {
        vault.delegate(who);
    }

    function undelegate(ECOxVestingVault vault) public {
        vault.undelegate();
    }
}
