// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ECOxChunkedLockup} from "../../ECOxChunkedLockup.sol";
import {ECOxStaking} from "currency/governance/community/ECOxStaking.sol";

contract MockBeneficiary {
    function claim(ECOxChunkedLockup vault) public {
        vault.claim();
    }

    function unstake(ECOxChunkedLockup vault, uint256 amount) public returns (uint256) {
        return vault.unstake(amount);
    }

    function stake(ECOxChunkedLockup vault, uint256 amount) public {
        vault.stake(amount);
    }

    function delegate(ECOxChunkedLockup vault, address who) public {
        vault.delegate(who);
    }

    function enableDelegation(ECOxChunkedLockup vault) public {
        ECOxStaking stakedToken = ECOxStaking(vault.stakedToken());
        stakedToken.enableDelegationTo();
    }
}
