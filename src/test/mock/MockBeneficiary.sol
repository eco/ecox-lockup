// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ECOxLockupVault} from "../../ECOxLockupVault.sol";
import {ECOxStaking} from "currency/governance/community/ECOxStaking.sol";

contract MockBeneficiary {
    function claim(ECOxLockupVault vault) public {
        vault.claim();
    }

    function unstake(ECOxLockupVault vault, uint256 amount) public returns (uint256) {
        return vault.unstake(amount);
    }

    function stake(ECOxLockupVault vault, uint256 amount) public {
        vault.stake(amount);
    }

    function delegate(ECOxLockupVault vault, address who) public {
        vault.delegate(who);
    }

    function enableDelegation(ECOxLockupVault vault) public {
        ECOxStaking lockup = ECOxStaking(vault.lockup());
        lockup.enableDelegationTo();
    }
}
