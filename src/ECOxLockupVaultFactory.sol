// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IVestingVaultFactory} from "vesting/interfaces/IVestingVaultFactory.sol";
import {ECOxLockupVault} from "./ECOxLockupVault.sol";

contract ECOxLockupVaultFactory is IVestingVaultFactory {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ClonesWithImmutableArgs for address;

    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @notice Creates a new vesting vault
     * @param token The ERC20 token to vest over time
     * @param beneficiary The address who will receive tokens over time
     * @param admin The address that can claw back unvested funds
     */
    function createVault(
        address token,
        address beneficiary,
        address admin,
        uint256[] calldata amounts,
        uint256[] calldata timestamps
    ) public returns (address) {
        if (amounts.length != timestamps.length) revert InvalidParams();

        bytes memory data = abi.encodePacked(
            token,
            beneficiary,
            amounts.length,
            amounts,
            timestamps
        );
        ECOxLockupVault clone = ECOxLockupVault(implementation.clone(data));

        uint256 totalTokens = clone.vestedOn(type(uint256).max);
        IERC20Upgradeable(token).safeTransferFrom(
            msg.sender,
            address(this),
            totalTokens
        );
        IERC20Upgradeable(token).approve(address(clone), totalTokens);
        clone.initialize(admin);
        emit VaultCreated(token, beneficiary, address(clone));
        return address(clone);
    }
}