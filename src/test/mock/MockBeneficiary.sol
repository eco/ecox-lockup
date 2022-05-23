// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;
import {ECOxVestingVault} from "../../ECOxVestingVault.sol";

contract MockBeneficiary {
    function claim(ECOxVestingVault vault) public {
        vault.claim();
    }

    function unstakeVestedECOx(ECOxVestingVault vault) public returns (uint256) {
        return vault.unstakeVestedECOx();
    }
}
