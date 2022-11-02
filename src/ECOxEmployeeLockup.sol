pragma solidity 0.8.15;

import {ECOxLockupVault} from "./ECOxLockupVault.sol";
import {IECOx} from "./interfaces/IECOx.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";

/**
 * @notice ECOxEmployeeLockup contract holds ECOx for employees until a cliff date has passed.
 * Notably it is initialized with only one timestamp (cliff date) and one initial token amount (0).
 * As a result, the methods found in ChunkedVestingVaultArgs will not provide useful information
 * and any methods referring to amounts, timestamps and chunks will reflect the fact that there is
 * only one of each.
 */
contract ECOxEmployeeLockup is ECOxLockupVault {
    /**
     * @notice calculates tokens vested at a given timestamp
     * @param timestamp The time for which vested tokens are being calculated
     * @return amount of tokens vested at timestamp
     */
    function vestedOn(uint256 timestamp)
        public
        view
        override
        returns (uint256 amount)
    {
        return
            timestamp >= this.timestampAtIndex(0)
                ? token().balanceOf(address(this)) +
                    IERC20Upgradeable(lockup).balanceOf(address(this))
                : 0;
    }

    /**
     * @notice helper function unstaking required tokens before they are claimed
     * @param amount amount of vested tokens being claimed
     */
    function onClaim(uint256 amount) internal override {
        uint256 balance = token().balanceOf(address(this));
        if (balance < amount) {
            _unstake(amount - balance);
        }
    }
}
